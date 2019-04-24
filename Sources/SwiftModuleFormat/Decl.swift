import Foundation

public enum _DeclCode : UInt32 {
    case TYPE_ALIAS = 60
    case GENERIC_TYPE_PARAM
    case ASSOCIATED_TYPE
    case STRUCT
    case CONSTRUCTOR
    case VAR
    case PARAM
    case FUNC
    case OPAQUE_TYPE
    case PATTERN_BINDING
    case PROTOCOL
    case TI_DEFAULT_WITNESS_TABLE
    case PREFIX_OPERATOR
    case POSTFIX_OPERATOR
    case INFIX_OPERATOR
    case CLASS
    case ENUM
    case ENUM_ELEMENT
    case SUBSCRIPT
    case EXTENSION
    case DESTRUCTOR
    case PRECEDENCE_GROUP
    case ACCESSOR
}

public enum _DeclOtherCode : UInt32 {
    case PARAMETERLIST = 210
    case FOREIGN_ERROR_CONVENTION = 212
    case DECL_CONTEXT = 213
    case XREF_TYPE_PATH_PIECE = 214
    case XREF_VALUE_PATH_PIECE = 215
    case XREF_EXTENSION_PATH_PIECE = 216
    case XREF_OPERATOR_OR_ACCESSOR_PATH_PIECE = 217
    case XREF_GENERIC_PARAM_PATH_PIECE = 218
    case XREF_INITIALIZER_PATH_PIECE = 219
    case ABSTRACT_CLOSURE_EXPR_CONTEXT = 220
    case PATTERN_BINDING_INITIALIZER_CONTEXT = 221
    case DEFAULT_ARGUMENT_INITIALIZER_CONTEXT = 222
    case TOP_LEVEL_CODE_DECL_CONTEXT = 223
    case GENERIC_PARAM_LIST = 230
    case GENERIC_SIGNATURE = 231
    case TI_GENERIC_REQUIREMENT
    case TI_LAYOUT_REQUIREMENT
    case SIL_GENERIC_ENVIRONMENT = 235
    case SUBSTITUTION_MAP = 236
    case LOCAL_DISCRIMINATOR = 237
    case PRIVATE_DISCRIMINATOR = 238
    case FILENAME_FOR_PRIVATE = 239
    
    case ABSTRACT_PROTOCOL_CONFORMANCE = 240
    case NORMAL_PROTOCOL_CONFORMANCE = 241
    case SPECIALIZED_PROTOCOL_CONFORMANCE = 242
    case INHERITED_PROTOCOL_CONFORMANCE = 243
    case INVALID_PROTOCOL_CONFORMANCE = 244
    
    case SIL_LAYOUT = 245
    case NORMAL_PROTOCOL_CONFORMANCE_ID = 246
    case PROTOCOL_CONFORMANCE_XREF = 247
    case MEMBERS = 248
    case XREF = 249
    case INLINABLE_BODY_TEXT = 250
    case SELF_PROTOCOL_CONFORMANCE = 251
    
    case XREF_OPAQUE_RETURN_TYPE_PATH_PIECE = 252
}

public enum _DeclAttrCode : UInt32 {
    case SILGenName = 0
    case Available = 1
    case Final = 2
    case ObjC = 3
    case Required = 4
    case Optional = 5
    case DynamicCallable = 6
    case Exported = 8
    case DynamicMemberLookup = 9
    case NSCopying = 10
    case IBAction = 11
    case IBDesignable = 12
    case IBInspectable = 13
    case IBOutlet = 14
    case NSManaged = 15
    case Lazy = 16
    case LLDBDebuggerFunction = 17
    case UIApplicationMain = 18
    case UnsafeNoObjCTaggedPointer = 19
    case Inline = 20
    case Semantics = 21
    case Dynamic = 22
    case Infix = 23
    case Prefix = 24
    case Postfix = 25
    case Transparent = 26
    case RequiresStoredPropertyInits = 27
    case NonObjC = 30
    case FixedLayout = 31
    case Inlinable = 32
    case Specialize = 33
    case ObjCMembers = 34
    case Consuming = 40
    case Mutating = 41
    case NonMutating = 42
    case Convenience = 43
    case Override = 44
    case HasStorage = 45
    case AccessControl = 46
    case SetterAccess = 47
    case RawDocComment = 48
    case ReferenceOwnership = 49
    case Effects = 50
    case ObjCBridged = 51
    case NSApplicationMain = 52
    case ObjCNonLazyRealization = 53
    case SynthesizedProtocol = 54
    case Testable = 55
    case Alignment = 56
    case Rethrows = 57
    case SwiftNativeObjCRuntimeBase = 59
    case DeclModifier = 60
    case WarnUnqualifiedAccess = 61
    case ShowInInterface = 62
    case CDecl = 63
    case UsableFromInline = 64
    case DiscardableResult = 65
    case GKInspectable = 66
    case Implements = 67
    case ObjCRuntimeName = 68
    case StaticInitializeObjCMetadata = 69
    case RestatedObjCConformance = 70
    case ImplicitlyUnwrappedOptional = 72
    case Optimize = 73
    case ClangImporterSynthesizedType = 74
    case WeakLinked = 75
    case Frozen = 76
    case ForbidSerializingReference = 77
    case HasInitialValue = 78
    case NonOverride = 79
    case DynamicReplacement = 80
    case Borrowed = 81
    case PrivateImport = 82
    case AlwaysEmitIntoClient = 83
    case ImplementationOnly = 84
    case Custom = 85
}

public struct DeclAttribute {
    public typealias Code = _DeclAttrCode
    
    public enum Entry {
        case unknown(String)
    }
    
    public var entry: Entry
}

public enum DeclBaseName : CustomStringConvertible {
    case normal(String)
    case `subscript`
    case constructor
    case destructor
    
    public var identifier: String {
        switch self {
        case .normal(let s): return s
        case .subscript: return "subscript"
        case .constructor: return "init"
        case .destructor: return "deinit"
        }
    }
    
    public var description: String {
        return identifier
    }
}

public class Decl : CustomDebugStringConvertible {
    public typealias Code = _DeclCode
    public typealias OtherCode = _DeclOtherCode
    
    public var isImplicit: Bool = false
    
    public var attributes: [DeclAttribute] = []
    
    public init() {
    }
    
    public var debugDescription: String {
        var str = "\(type(of: self))"
        let items = debugDescriptionItems
        if !items.isEmpty {
            str += "(" + items.joined(separator: ", ") + ")"
        }
        return str
    }
    
    public var debugDescriptionItems: [String] {
        return []
    }
}

public final class UnknownDecl : Decl {
    public var kind: String = ""
    
    public override init() {}
    
    public override var debugDescriptionItems: [String] {
        return ["kind=\(kind)"]
    }
}

public class ValueDecl : Decl {
    public var name: String = ""
    public var isObjC: Bool = false
    
    public override var debugDescriptionItems: [String] {
        var items: [String] = []
        if !name.isEmpty {
            items.append(name)
        }
        return items
    }
}

public class TypeDecl : ValueDecl {}

public class GenericTypeDecl : TypeDecl {}

public class NominalTypeDecl : GenericTypeDecl {}

public final class ClassDecl : NominalTypeDecl {
    public var requiresStoredPropertyInits: Bool = false
    public var inheritsSuperclassInits: Bool = false
}


