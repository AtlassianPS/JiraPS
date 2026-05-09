// Shared infrastructure for JiraPS domain types: identity comparison helpers,
// transformation utilities, and the base ArgumentTransformationAttribute.
// Loaded once at module import via Add-Type from JiraPS.psm1 (#region Dependencies).

using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Threading;

namespace AtlassianPS.JiraPS
{
    internal static class JiraTypeIdentity
    {
        private sealed class ObjectOrderToken
        {
            public readonly int Value;

            public ObjectOrderToken(int value)
            {
                Value = value;
            }
        }

        private static readonly StringComparer Comparer = StringComparer.OrdinalIgnoreCase;
        private static readonly ConditionalWeakTable<object, ObjectOrderToken> ObjectOrder = new ConditionalWeakTable<object, ObjectOrderToken>();
        private static int NextObjectOrder;

        public static bool Equals(string left, string right)
        {
            return Comparer.Equals(Normalize(left), Normalize(right));
        }

        public static int Compare(string left, string right)
        {
            return Comparer.Compare(Normalize(left), Normalize(right));
        }

        public static int CompareObjects(string left, string right, object leftObject, object rightObject)
        {
            var normalizedLeft = Normalize(left);
            var normalizedRight = Normalize(right);
            var leftHasIdentity = normalizedLeft.Length > 0;
            var rightHasIdentity = normalizedRight.Length > 0;

            if (leftHasIdentity && rightHasIdentity)
            {
                return Comparer.Compare(normalizedLeft, normalizedRight);
            }

            if (leftHasIdentity) { return 1; }
            if (rightHasIdentity) { return -1; }
            if (ReferenceEquals(leftObject, rightObject)) { return 0; }

            return GetObjectOrder(leftObject).CompareTo(GetObjectOrder(rightObject));
        }

        public static bool IdentityEquals<T>(T leftObject, T rightObject, string leftIdentity, string rightIdentity)
            where T : class
        {
            if (ReferenceEquals(rightObject, null)) { return false; }
            if (ReferenceEquals(leftObject, rightObject)) { return true; }
            if (string.IsNullOrEmpty(leftIdentity) || string.IsNullOrEmpty(rightIdentity)) { return false; }

            return Equals(leftIdentity, rightIdentity);
        }

        public static int IdentityGetHashCode(string identity)
        {
            if (string.IsNullOrEmpty(identity)) { return 0; }
            return GetHashCode(identity);
        }

        public static int IdentityCompare<T>(T leftObject, T rightObject, string leftIdentity, string rightIdentity)
            where T : class
        {
            if (ReferenceEquals(rightObject, null)) { return 1; }
            return CompareObjects(leftIdentity, rightIdentity, leftObject, rightObject);
        }

        public static int CompareToObject<T>(object value, Func<T, int> compare, string typeName)
            where T : class
        {
            if (value == null) { return 1; }

            var other = value as T;
            if (other == null) { throw new ArgumentException("Object must be " + typeName + ".", "obj"); }

            return compare(other);
        }

        public static int GetHashCode(string value)
        {
            return Comparer.GetHashCode(Normalize(value));
        }

        private static string Normalize(string value)
        {
            return value ?? string.Empty;
        }

        private static int GetObjectOrder(object value)
        {
            return ObjectOrder.GetValue(value, CreateObjectOrderToken).Value;
        }

        private static ObjectOrderToken CreateObjectOrderToken(object value)
        {
            return new ObjectOrderToken(Interlocked.Increment(ref NextObjectOrder));
        }
    }

    // Internal helper shared by JiraPS argument transformers that fan out
    // array arguments (e.g. [User[]], [Group[]]). IssueTransformation does
    // not use this — singular [Issue] parameters must not auto-iterate a
    // bound array; callers pipeline-iterate instead.
    //
    // Throw vs. pass-through (binder fallthrough): see AGENTS.md
    // "Argument transformation attributes". When a parameter shares
    // ValueFromPipeline with another parameter set that expects a different
    // type, TransformOne must return inputData unchanged for unrecognized
    // shapes (see VersionTransformationAttribute). Otherwise TransformOne
    // should throw ArgumentTransformationMetadataException.
    //
    // PowerShell's ArgumentTransformationAttribute is invoked once with
    // whatever the caller typed — a single value OR an enumerable bound to a
    // [T[]] parameter (e.g. -User $a, $b on Remove-JiraGroupMember). For array
    // parameters we walk the enumerable so each element is transformed in
    // isolation and element coercion sees the right runtime type.
    internal static class JiraTransform
    {
        public static bool IsJiraDomainObject(object value)
        {
            if (value == null) { return false; }

            var pso = value as System.Management.Automation.PSObject;
            if (pso != null)
            {
                if (pso.TypeNames != null)
                {
                    foreach (var typeName in pso.TypeNames)
                    {
                        if (!string.IsNullOrEmpty(typeName)
                            && (typeName.StartsWith("AtlassianPS.JiraPS.", StringComparison.Ordinal)
                                || typeName.StartsWith("JiraPS.", StringComparison.Ordinal)))
                        {
                            return true;
                        }
                    }
                }
                value = pso.BaseObject;
                if (value == null) { return false; }
            }

            var valueType = value.GetType();
            return valueType != null && string.Equals(valueType.Namespace, "AtlassianPS.JiraPS", StringComparison.Ordinal);
        }

        public static Uri ToUri(object value)
        {
            if (value == null) { return null; }

            var uri = value as Uri;
            if (uri != null) { return uri; }

            var text = value.ToString();
            if (string.IsNullOrWhiteSpace(text)) { return null; }

            return new Uri(text, UriKind.RelativeOrAbsolute);
        }

        public static bool IsNumericType(object value)
        {
            return value is int || value is long || value is short || value is byte
                || value is uint || value is ulong || value is ushort || value is sbyte;
        }

        public static object TransformOrFanout(object inputData, Func<object, object> perItem)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            // Strings are IEnumerable<char>; treat them as scalars.
            if (value is string) { return perItem(inputData); }

            // Hashtables are IEnumerable<DictionaryEntry>; never fan-out.
            if (value is System.Collections.IDictionary) { return perItem(inputData); }

            // C# 5 compatible (PS 5.1's bundled csc.exe): use `as` + null check
            // instead of pattern-matching `is X identifier` (C# 7+).
            var enumerable = value as System.Collections.IEnumerable;
            if (enumerable != null)
            {
                var results = new System.Collections.Generic.List<object>();
                foreach (var item in enumerable) { results.Add(perItem(item)); }
                return results.ToArray();
            }

            return perItem(inputData);
        }
    }


    // CRTP base for domain objects that compare by a single string identity
    // (Key, Name, AccountId, Id, etc.). Subclasses implement GetIdentity()
    // and ToString(); the five interface methods are provided here once.
    public abstract class JiraIdentityObject<TSelf> : IEquatable<TSelf>, IComparable<TSelf>, IComparable
        where TSelf : JiraIdentityObject<TSelf>
    {
        protected abstract string GetIdentity();

        public bool Equals(TSelf other)
        {
            return JiraTypeIdentity.IdentityEquals(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        public override bool Equals(object obj)
        {
            return Equals(obj as TSelf);
        }

        public override int GetHashCode()
        {
            return JiraTypeIdentity.IdentityGetHashCode(GetIdentity());
        }

        public int CompareTo(TSelf other)
        {
            return JiraTypeIdentity.IdentityCompare(this, other, GetIdentity(), other != null ? other.GetIdentity() : string.Empty);
        }

        int IComparable.CompareTo(object obj)
        {
            return JiraTypeIdentity.CompareToObject<TSelf>(obj, CompareTo, typeof(TSelf).FullName);
        }
    }

    // Unified base for all JiraPS argument-transformation attributes.
    // Leaf transformers override TargetType + FromString. Core transformers
    // additionally override FromNumericScalar and/or MapLegacyObject to
    // handle numeric IDs and v2 PSCustomObject shapes.
    public abstract class JiraTransformationAttribute : System.Management.Automation.ArgumentTransformationAttribute
    {
        protected abstract Type TargetType { get; }
        protected abstract object FromString(string value);

        // Override to false for parameters that must not auto-iterate arrays
        // (e.g. Issue, where callers pipeline-iterate instead).
        protected virtual bool UseFanOut { get { return true; } }

        // Override to accept bare int/long values as IDs (Version, Filter, Project).
        protected virtual object FromNumericScalar(long value) { return null; }

        // Legacy PSTypeName tags to recognize when mapping v2 PSCustomObjects.
        // Return null (default) to skip legacy mapping entirely.
        protected virtual string[] LegacyTypeNames { get { return null; } }

        // Map properties from a legacy PSCustomObject to a new domain object.
        // Only called when the PSObject's TypeNames contain one of LegacyTypeNames.
        protected virtual object MapLegacyObject(System.Management.Automation.PSObject pso) { return null; }

        public sealed override object Transform(System.Management.Automation.EngineIntrinsics engineIntrinsics, object inputData)
        {
            if (UseFanOut) return JiraTransform.TransformOrFanout(inputData, TransformOne);
            return TransformOne(inputData);
        }

        private object TransformOne(object inputData)
        {
            if (inputData == null) return null;

            var pso = inputData as System.Management.Automation.PSObject;
            object value = pso != null ? pso.BaseObject : inputData;

            var targetType = TargetType;
            if (targetType.IsInstanceOfType(value)) return value;

            if (JiraTransform.IsNumericType(value))
            {
                var numeric = FromNumericScalar(System.Convert.ToInt64(value));
                if (numeric != null) return numeric;
            }

            var text = value as string;
            if (text != null)
            {
                if (string.IsNullOrWhiteSpace(text))
                {
                    throw new System.Management.Automation.ArgumentTransformationMetadataException(
                        "Cannot bind an empty or whitespace string to a " + targetType.FullName + " parameter.");
                }
                return FromString(text);
            }

            var legacyNames = LegacyTypeNames;
            if (legacyNames != null && pso != null && pso.TypeNames != null)
            {
                foreach (var tag in legacyNames)
                {
                    if (pso.TypeNames.Contains(tag))
                    {
                        return MapLegacyObject(pso);
                    }
                }
            }

            if (JiraTransform.IsJiraDomainObject(inputData)) { return inputData; }

            throw new System.Management.Automation.ArgumentTransformationMetadataException(string.Format(
                "Cannot convert value of type '{0}' to {1}. Expected a non-empty string or an existing {1} object.",
                value.GetType().FullName,
                targetType.FullName));
        }
    }
}
