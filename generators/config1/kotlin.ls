use Symbol;
use SymbolTable;
use Type;
use Function;
use CustomList;
use Variable;
use GeneratorClassHelper;
use TypeParam;
use AbstractType;
use Pair;
use AbstractFunction;

class Program {
  prog("${imports : Imports}${decls : OptionalGlobalDeclarationList}
  ${main : MainDeclaration}\n") {
    decls.symbols_before = (SymbolTable:init);
    main.symbols_before = decls.symbols_after;
  }
}

class Imports {
  imports ("import java.util.Objects\n") {}
}

class OptionalGlobalDeclarationList {

  inh symbols_before : SymbolTable;

  syn symbols_after : SymbolTable;
  
  no_decls ("") {
    this.symbols_after = this.symbols_before;
  }

  @weight(100)
  decls ("${decls : GlobalDeclarationList}\n") {
    decls.symbols_before = this.symbols_before;
    this.symbols_after = decls.symbols_after;
  }

}

@list(200)
class GlobalDeclarationList {

  syn symbols_after : SymbolTable;

  inh symbols_before : SymbolTable;

  @weight(1)
  one_decl ("${decl : GlobalDeclaration}") {
    decl.symbols_before = this.symbols_before;
    this.symbols_after = decl.symbols_after;
  }

  @weight(10)
  mult_decl ("${decl : GlobalDeclaration}\n
              ${rest : GlobalDeclarationList}") {
    decl.symbols_before = this.symbols_before;

    rest.symbols_before = decl.symbols_after;

    this.symbols_after = rest.symbols_after;
  }

}

class GlobalDeclaration {

  syn symbols_after : SymbolTable;

  inh symbols_before : SymbolTable;

  global_func_decl ("${func_decl : FunctionDeclaration}") {
    func_decl.in_interface = false;
    func_decl.symbols_before = this.symbols_before;
    this.symbols_after = (SymbolTable:put this.symbols_before func_decl.symbol);
  }

  @weight(10)
  global_class_decl("${class_decl : ClassDeclaration}") {
    class_decl.symbols_before = this.symbols_before;
    this.symbols_after = (SymbolTable:put this.symbols_before class_decl.symbol);
  }
}

class ClassDeclaration {
  syn symbol : Type;
  inh symbols_before : SymbolTable;

  class_decl("${open : OptionalOpen}${class_or_interface : ClassOrInterface} ${ident : DefIdentifier}${type_params : OptionalTypeParamters}${primary_constructor : OptionalPrimaryConstructor} ${supertypes : TypeInheritance}{\+${body : ClassMemberList}\n${overrides: MandatoryOverrides}\-}\n") {
    loc supertypes = (if (== (CustomList:getSize supertypes.supertypes) 0) (CustomList:create (SymbolTable:getKotlinAnyType this.symbols_before)) supertypes.supertypes); 
    loc class_type = (if (== (CustomList:getSize type_params.type_params) 0)
      (Type:create ident.name class_or_interface.is_interface (or open.is_open class_or_interface.is_interface) (if (== primary_constructor.params nil) (CustomList:empty) (CustomList:create primary_constructor.params)) primary_constructor.property_constrcutor_params .supertypes)
      (AbstractType:create ident.name class_or_interface.is_interface (or open.is_open class_or_interface.is_interface) (if (== primary_constructor.params nil) (CustomList:empty) (CustomList:create primary_constructor.params)) primary_constructor.property_constrcutor_params .supertypes type_params.type_params)
    );
      

    ident.symbols_before = this.symbols_before;

    type_params.symbols_before = (SymbolTable:enterScope this.symbols_before);
    type_params.allow_modifier = true;
    type_params.allow_reified = false;

    primary_constructor.symbols_before = type_params.symbols_after;
    primary_constructor.is_interface = class_or_interface.is_interface;

    supertypes.symbols_before = primary_constructor.symbols_after;
    supertypes.is_interface = class_or_interface.is_interface;

    body.symbols_before = primary_constructor.symbols_after;
    body.class_type_before = .class_type;
    body.non_property_constrcutor_params = primary_constructor.non_property_constrcutor_params;

    overrides.symbols_before = body.symbols_after;
    overrides.class_type_before = .class_type; 

    this.symbol = body.class_type_after;
  }
}

class OptionalTypeParamters {
  inh symbols_before : SymbolTable;
  inh allow_modifier : boolean;
  inh allow_reified : boolean;

  syn type_params : CustomList;
  syn symbols_after : SymbolTable;

  no_type_params ("") {
    this.type_params = (CustomList:empty);
    this.symbols_after = this.symbols_before;
  }

  type_params ("<${list : TypeParameterList}> ") {
    list.symbols_before = this.symbols_before;
    list.allow_modifier = this.allow_modifier;
    list.allow_reified = this.allow_reified;

    this.type_params = list.type_params;
    this.symbols_after = list.symbols_after;
  }
}

@list(2)
class TypeParameterList {
  inh symbols_before : SymbolTable;
  inh allow_modifier : boolean;
  inh allow_reified : boolean;

  syn type_params : CustomList;
  syn symbols_after : SymbolTable;

  one ("${type_param : TypeParameter}") {
    type_param.symbols_before = this.symbols_before;
    type_param.allow_modifier = this.allow_modifier;
    type_param.allow_reified = this.allow_reified;

    this.type_params = (CustomList:create type_param.type_param);
    this.symbols_after = (SymbolTable:put this.symbols_before type_param.type_param);
  }
}

class TypeParameter {
  inh symbols_before : SymbolTable;
  inh allow_modifier : boolean;
  inh allow_reified : boolean;

  syn type_param : Type;

  type_param("${reified : OptionalReified}${mod : OptionalVarianceModifier}${ident : DefIdentifier}${upperbound : OptionalTypeUpperBound}") {
    loc upperbound = (if upperbound.has_type upperbound.type (SymbolTable:getKotlinAnyType this.symbols_before));
    loc supertypes = (if upperbound.has_type (CustomList:create upperbound.type) (CustomList:empty));

    reified.allow_reified = this.allow_reified;

    mod.allow_modifier = this.allow_modifier;

    ident.symbols_before = this.symbols_before;

    upperbound.symbols_before = this.symbols_before;
    upperbound.required = false; 

    this.type_param = (TypeParam:create ident.name mod.modifier reified.is_reified .upperbound .supertypes);
  }
}

class OptionalReified {
  grd valid;

  inh allow_reified : boolean;

  syn is_reified : boolean;

  no_reified("") {
    this.valid = true;

    this.is_reified = false;
  }

  reified("reified ") {
    this.valid = this.allow_reified;

    this.is_reified = true;
  }
}

class OptionalVarianceModifier {
  grd valid;

  inh allow_modifier : boolean;

  syn modifier : String;

  none("") {
    this.valid = true;

    this.modifier = "inv";
  }

  in("in ") {
    this.valid = this.allow_modifier;

    this.modifier = "in";
  }

  out("out ") {
    this.valid = this.allow_modifier;

    this.modifier = "out";
  }
}

class MandatoryOverrides {
  grd valid;

  inh symbols_before : SymbolTable;
  inh class_type_before : Type;

  no_overrides ("") {
    this.valid = (Type:isInterface this.class_type_before);
  }

  overrides ("${properties : MandatoryPropertyOverrideList}${functions : MandatoryFunctionOverrideList}") {
    this.valid = (not (Type:isInterface this.class_type_before));
    properties.symbols_before = this.symbols_before;
    properties.properties = (Type:getAbstractProperties this.class_type_before);

    functions.symbols_before = this.symbols_before;
    functions.functions = (Type:getAbstractMemberFunctions this.class_type_before);
  }
}

class MandatoryPropertyOverrideList {
  grd valid;

  inh properties : CustomList;
  inh symbols_before : SymbolTable;

  none("") {
    this.valid = (== (CustomList:getSize this.properties) 0);
  }

  mult("${property : MandatoryPropertyOverride}\n${rest : MandatoryPropertyOverrideList}") {
    this.valid = (> (CustomList:getSize this.properties) 0);
    
    property.property = (CustomList:asVariable (CustomList:getHead this.properties));
    property.symbols_before = this.symbols_before;

    rest.properties = (CustomList:getTail this.properties);
    rest.symbols_before = this.symbols_before;
  }
}

class MandatoryPropertyOverride {
  inh property : Variable;
  inh symbols_before : SymbolTable;

  property ("override ${mod : InsertString} ${name : InsertString}: ${type : InsertString} = ${expr : Expr}") {
    mod.string = (if (Variable:getIsMutable this.property) "var" "val");

    name.string = (Variable:getName this.property);

    type.string = (Type:getName (Variable:getType this.property));

    expr.expected_type = (Variable:getType this.property);
    expr.symbols_before = this.symbols_before;
  }
}

class MandatoryFunctionOverrideList {
  grd valid;

  inh functions : CustomList;
  inh symbols_before : SymbolTable;

  none("") {
    this.valid = (== (CustomList:getSize this.functions) 0);
  }

  mult("${function : MandatoryFunctionOverride}\n${rest : MandatoryFunctionOverrideList}") {
    this.valid = (> (CustomList:getSize this.functions) 0);

    function.function = (CustomList:getHead this.functions);
    function.symbols_before = this.symbols_before;

    rest.functions = (CustomList:getTail this.functions);
    rest.symbols_before = this.symbols_before;
  }
}

class MandatoryFunctionOverride {
  inh function : Function;
  inh symbols_before : SymbolTable;

  fun_expr ("override fun ${name : InsertString}(${params : MandatoryParameterList}): ${type : InsertString} = ${expr : Expr}") {
    name.string = (Function:getName this.function);

    type.string = (Type:getName (Function:getReturnType this.function));

    params.params = (Function:getParams this.function);
    
    expr.expected_type = (Function:getReturnType this.function);
    expr.symbols_before = this.symbols_before;
  }

  fun_body ("override fun ${name : InsertString}(${params : MandatoryParameterList}): ${type : InsertString} {\+
          ${body : FunctionBody}\-
        }\n") {
    name.string = (Function:getName this.function);

    params.params = (Function:getParams this.function);

    type.string = (Type:getName (Function:getReturnType this.function));
    
    body.expected_return_type = (Function:getReturnType this.function);
    body.symbols_before = this.symbols_before;
  }
}

class MandatoryParameterList {
  grd valid;
  inh params : CustomList;

  none("") {
    this.valid = (== (CustomList:getSize this.params) 0);
  }

  mult("${name : InsertString}: ${type : InsertString}, ${rest : MandatoryParameterList}") {
    loc param = (CustomList:asVariable (CustomList:getHead this.params));
    this.valid = (> (CustomList:getSize this.params) 0);

    name.string = (Variable:getName .param);

    type.string = (Type:getName (Variable:getType .param));

    rest.params = (CustomList:getTail this.params);
  }
}

class TypeInheritance {
  grd valid;

  inh symbols_before : SymbolTable;
  inh is_interface : boolean;

  syn supertypes : CustomList;

  @weight(1)
  no_inheritance("") {
    this.valid = true;
    this.supertypes = (CustomList:empty);
  }

  @weight(2)
  inheritance(": ${supertypes : TypeInheritanceList}") {
    loc candidate_types = (CustomList:create (SymbolTable:visibleTypes this.symbols_before (not this.is_interface) true false));
    this.valid = (> (CustomList:getSize .candidate_types) 0);
    supertypes.candidate_types = .candidate_types;
    supertypes.symbols_before = this.symbols_before;

    this.supertypes = supertypes.supertypes;
  }
}

class TypeInheritanceList {
  grd valid;
  grd valid2;

  inh symbols_before : SymbolTable;
  inh candidate_types : CustomList;

  syn supertypes : CustomList;

  skip("${rest : TypeInheritanceList}") {
    this.valid = (> (CustomList:getSize this.candidate_types) 0);
    this.valid2 = true;

    rest.symbols_before = this.symbols_before;
    rest.candidate_types = (CustomList:getTail this.candidate_types);

    this.supertypes = rest.supertypes;
  }

  one("${type_delegation : TypeDelegation}") {
    loc chosen_type = (CustomList:asType (CustomList:getHead this.candidate_types));
    this.valid = (> (CustomList:getSize this.candidate_types) 0);
    this.valid2 = true;

    type_delegation.type = .chosen_type;
    type_delegation.symbols_before = this.symbols_before;

    this.supertypes = (CustomList:create .chosen_type);
  }

  mult("${type_delegation : TypeDelegation}, ${rest : TypeInheritanceList}") {
    loc chosen_type = (CustomList:asType (CustomList:getHead this.candidate_types));
    this.valid = (> (CustomList:getSize this.candidate_types) 0);
    this.valid2 = (or (Type:isInterface .chosen_type) (Type:containsNoClasses rest.supertypes));

    type_delegation.type = .chosen_type;
    type_delegation.symbols_before = this.symbols_before;

    rest.symbols_before = this.symbols_before;
    rest.candidate_types = (CustomList:getTail this.candidate_types);

    this.supertypes = (CustomList:prepend rest.supertypes .chosen_type);
  }
}

class TypeDelegation {
  grd valid;

  inh type : Type;
  inh symbols_before : SymbolTable;

  constructor ("${name : InsertString}(${chosen_params : UseConstructor}${args : ArgumentList})") {
    this.valid = (not (Type:isInterface this.type));

    name.string = (Type:getName this.type);

    chosen_params.class_type = this.type;

    args.symbols_before = this.symbols_before;
    args.expected_params = chosen_params.params;
  }

  no_constructor ("${name : InsertString}") {
    this.valid = (Type:isInterface this.type);

    name.string = (Type:getName this.type);
  }
}

class ClassOrInterface {
  syn is_interface : Boolean;

  @weight(8)
  class_("class") {
    this.is_interface = false;
  }

  @weight(2)
  interface("interface") {
    this.is_interface = true;
  }
}

class OptionalOpen {
  syn is_open : Boolean;

  no_open("") {
    this.is_open = false;
  }

  open("open ") {
    this.is_open = true;
  }
}

class ClassMemberList {
  inh symbols_before : SymbolTable;
  inh class_type_before : Type;
  inh non_property_constrcutor_params : CustomList;

  syn symbols_after : SymbolTable;
  syn class_type_after : Type;

  member ("${member : ClassMember}") {
    member.symbols_before = this.symbols_before;
    member.non_property_constrcutor_params = this.non_property_constrcutor_params;
    member.class_type_before = this.class_type_before;

    this.symbols_after = member.symbols_after;
    this.class_type_after = member.class_type_after;
  } 

  @weight(100)
  mult_members ("${member : ClassMember}\n${rest : ClassMemberList}") {
    member.symbols_before = this.symbols_before;
    member.non_property_constrcutor_params = this.non_property_constrcutor_params;
    member.class_type_before = this.class_type_before;

    rest.symbols_before = member.symbols_after;
    rest.non_property_constrcutor_params = this.non_property_constrcutor_params;
    rest.class_type_before = member.class_type_after;

    this.symbols_after = rest.symbols_after;
    this.class_type_after = rest.class_type_after;
  }
}

class ClassMember {
  grd valid;
  grd valid2;

  inh symbols_before : SymbolTable;
  inh class_type_before : Type;
  inh non_property_constrcutor_params : CustomList;

  syn symbols_after : SymbolTable;
  syn class_type_after : Type;

  property ("${decl : PropertyDeclaration}") {
    this.valid = true;
    this.valid2 = true;

    decl.symbols_before = this.symbols_before;
    decl.is_interface = (Type:isInterface this.class_type_before);
    this.symbols_after = (SymbolTable:put this.symbols_before decl.symbol);
    this.class_type_after = (Type:addProperty this.class_type_before decl.symbol);
  }

  init ("init {\+${stmts : Block}\-}") {
    this.valid = (not (Type:isInterface this.class_type_before));
    this.valid2 = true;

    stmts.symbols_before = (SymbolTable:enterScope (SymbolTable:putAll this.symbols_before this.non_property_constrcutor_params));

    this.symbols_after = this.symbols_before;
    this.class_type_after = this.class_type_before;
  }

  member_function ("${func : FunctionDeclaration}") {
    this.valid = true;
    this.valid2 = true;

    func.symbols_before = this.symbols_before;
    func.in_interface = (Type:isInterface this.class_type_before);

    this.symbols_after = (SymbolTable:put this.symbols_before func.symbol);
    this.class_type_after = (Type:addMemberFunction this.class_type_before func.symbol);
  }

  secondary_constructor ("constructor (${params : ParameterDeclarationList})${delagation : OptionalConstructorDelegation} {\+${stmts : Block}\-}") {
    this.valid = (not (Function:paramsClash (Type:getConstructors this.class_type_before) params.params));
    this.valid2 = (not (Type:isInterface this.class_type_before));

    params.symbols_before = (SymbolTable:enterScope this.symbols_before);

    delagation.symbols_before = (SymbolTable:putAll (SymbolTable:exitScope this.symbols_before) params.params);
    delagation.class_type_before = this.class_type_before;

    stmts.symbols_before = (SymbolTable:put params.symbols_after this.class_type_before);

    this.symbols_after = this.symbols_before;
    this.class_type_after = (Type:addConstrcutor this.class_type_before params.params);
  }
}

class PropertyDeclaration {  
  grd valid;
  grd valid2;

  syn symbol : Variable;

  inh symbols_before : SymbolTable;
  inh is_interface : boolean;

  var_decl ("${mod: VariableModifier} ${name : DefIdentifier}${type : OptionalTypeAnnotation} ${init : OptionalVariableInitialiation}\n${getter : OptionalPropertyGetter}${setter : OptionalPropertySetter}") {
    loc uses_field = (or getter.uses_field setter.uses_field);
    loc no_custom_accessor = (and (not getter.has_getter) (not setter.has_setter));
    loc has_all_accessors = (and getter.has_getter (or (not mod.is_mutable) setter.has_setter));
    loc mutable_and_missing_accessor = (and mod.is_mutable (or (and (not getter.has_getter) setter.has_setter) (and getter.has_getter (not setter.has_setter))));
    loc is_abstract = (and this.is_interface .no_custom_accessor);

    this.valid = (not (TypeParam:isContravariant (if type.has_type type.type init.type)));
    this.valid2 = (not (and (TypeParam:isCovariant (if type.has_type type.type init.type)) mod.is_mutable));

    type.symbols_before = this.symbols_before;
    type.required = true;
    
    name.symbols_before = this.symbols_before;

    getter.symbols_before = this.symbols_before;
    getter.property_type = type.type;
    getter.is_interface = this.is_interface;

    setter.symbols_before = this.symbols_before;
    setter.property_type = type.type;
    setter.is_interface = this.is_interface;
    setter.is_mutable = mod.is_mutable;

    init.symbols_before = this.symbols_before;
    init.expected_type = type.type;
    init.must_initialise = (or (or .uses_field (and .no_custom_accessor (not this.is_interface))) .mutable_and_missing_accessor);
    init.must_not_initialise = (or this.is_interface (and .has_all_accessors (not .uses_field)));

    this.symbol = (Variable:create name.name (if type.has_type type.type init.type) init.is_initialised mod.is_mutable .is_abstract);
  }
}

class OptionalPropertyGetter {
  grd valid;
  inh symbols_before : SymbolTable;
  inh is_interface : boolean;
  inh property_type : Type;

  syn has_getter : boolean;
  syn uses_field : boolean;
  
  no_getter ("") {
    this.valid = true;
    this.has_getter = false;
    this.uses_field = false;
  }

  getter_without_field ("get() {\+
          ${body : FunctionBody}\-
        }\n") {
    this.valid = true;
    body.symbols_before = (SymbolTable:enterScope this.symbols_before);
    body.expected_return_type = this.property_type;
    this.has_getter = true;
    this.uses_field = false;
  }

  getter_with_field ("get() {\+
          println(field)\n
          ${body : FunctionBody}\-
        }\n") {
    loc field = (Variable:create "field" this.property_type true false); 
    this.valid = (not this.is_interface);
    body.symbols_before = (SymbolTable:put (SymbolTable:enterScope this.symbols_before) .field);
    body.expected_return_type = this.property_type;
    this.has_getter = true;
    this.uses_field = true;
  }
}

class OptionalPropertySetter {
  grd valid1;
  grd valid2;
  inh symbols_before : SymbolTable;
  inh is_interface : boolean;
  inh property_type : Type;
  inh is_mutable : boolean;

  syn has_setter : boolean;
  syn uses_field : boolean;
  
  no_setter ("") {
    this.valid1 = true;
    this.valid2 = true;
    this.has_setter = false;
    this.uses_field = false;
  }

  setter_without_field ("set(value) {\+
          ${body : FunctionBody}\-
        }\n") {
    loc value = (Variable:create "value" this.property_type true false);
    this.valid1 = this.is_mutable;
    this.valid2 = true;
    body.symbols_before = (SymbolTable:put (SymbolTable:enterScope this.symbols_before) .value);
    body.expected_return_type = (SymbolTable:getAsType this.symbols_before "Unit");
    this.has_setter = true;
    this.uses_field = false;
  }

  setter_with_field ("set(value) {\+
          println(field)\n
          ${body : FunctionBody}\-
        }\n") {
    loc value = (Variable:create "value" this.property_type true false);
    loc field = (Variable:create "field" this.property_type true true); 
    this.valid1 = this.is_mutable;
    this.valid2 = (not this.is_interface);
    body.symbols_before = (SymbolTable:put (SymbolTable:put (SymbolTable:enterScope this.symbols_before) .field) .value);
    body.expected_return_type = (SymbolTable:getAsType this.symbols_before "Unit");
    this.has_setter = true;
    this.uses_field = true;
  }
}

class OptionalConstructorDelegation {
  grd valid;
  inh symbols_before : SymbolTable;
  inh class_type_before : Type;

  no_delegation ("") {
    this.valid = (== (CustomList:getSize (Type:getConstructors this.class_type_before)) 0);

  }

  delegation (": this(${chosen_params : UseConstructor}${args : ArgumentList})") {
    this.valid = (> (CustomList:getSize (Type:getConstructors this.class_type_before)) 0);
    chosen_params.class_type = this.class_type_before;
    args.symbols_before = this.symbols_before;
    args.expected_params = chosen_params.params;
  }
}

class UseConstructor {
  inh class_type : Type;
  syn params : CustomList;
  constructor(SymbolTable:visibleConstructors this.class_type) : CustomList {
    this.params = $;
  }
}

class OptionalPrimaryConstructor {
  grd valid;
  inh symbols_before : SymbolTable;
  inh is_interface : boolean;
  syn symbols_after : SymbolTable;
  syn params : CustomList;
  syn non_property_constrcutor_params : CustomList;
  syn property_constrcutor_params : CustomList;

  no_constructor("") {
    this.valid = true;
    this.params = nil;
    this.non_property_constrcutor_params = (CustomList:empty);
    this.property_constrcutor_params = (CustomList:empty);
    this.symbols_after = this.symbols_before;
  }

  @weight(100)
  constructor("(${constructorList: ConstructorList})") {
    this.valid = (not this.is_interface);
    constructorList.symbols_before = this.symbols_before;
    this.symbols_after = constructorList.symbols_after;
    this.params = constructorList.params;
    this.non_property_constrcutor_params = constructorList.non_property_constrcutor_params;
    this.property_constrcutor_params = constructorList.property_constrcutor_params;
  }
}

@list(5)
class ConstructorList {
  inh symbols_before : SymbolTable;
  syn symbols_after : SymbolTable;
  syn params : CustomList;
  syn non_property_constrcutor_params : CustomList;
  syn property_constrcutor_params : CustomList;

  no_param ("") {
    this.symbols_after = this.symbols_before;
    this.params = (CustomList:empty);
    this.non_property_constrcutor_params = (CustomList:empty);
    this.property_constrcutor_params = (CustomList:empty);
  }

  @weight(7)
  mult_param ("${param : ConstructorParameterDeclaration}, ${rest : ConstructorList}") {
    param.symbols_before = this.symbols_before;
    rest.symbols_before = (if param.add_to_properties (SymbolTable:put this.symbols_before param.symbol) this.symbols_before);
    this.symbols_after = rest.symbols_after;
    this.params = (CustomList:prepend rest.params param.symbol);
    this.non_property_constrcutor_params = (if param.add_to_properties rest.non_property_constrcutor_params (CustomList:prepend rest.non_property_constrcutor_params param.symbol));
    this.property_constrcutor_params = (if param.add_to_properties (CustomList:prepend rest.property_constrcutor_params param.symbol) rest.property_constrcutor_params);
  }
}

class ConstructorParameterDeclaration {
  grd valid;

  inh symbols_before : SymbolTable;
  syn symbol : Variable;
  syn add_to_properties : boolean;

  no_property("${param : ParameterDeclaration}") {
    this.valid = true;

    param.symbols_before = this.symbols_before;
    param.is_mutable = false;
    this.symbol = param.symbol;
    this.add_to_properties = false; 
  }

  val_property("val ${param : ParameterDeclaration}") {
    this.valid = (not (TypeParam:isContravariant (Variable:getType param.symbol)));

    param.symbols_before = this.symbols_before;
    param.is_mutable = false;
    this.symbol = param.symbol;
    this.add_to_properties = true;
  }

  var_property("var ${param : ParameterDeclaration}") {
    this.valid = (not (TypeParam:isContravariant (Variable:getType param.symbol)));

    param.symbols_before = this.symbols_before;
    param.is_mutable = true;
    this.symbol = param.symbol;
    this.add_to_properties = true;
  }
}

class FunctionDeclaration {
  grd valid;
  grd valid2;

  syn symbol : Function;

  inh symbols_before : SymbolTable;
  inh in_interface : boolean;

  func_decl_no_body ("fun ${type_params : OptionalTypeParamters}${name : DefIdentifier}(${params : ParameterDeclarationList})${ret_type : OptionalTypeAnnotation}") {
    loc function_symbol = (if (== (CustomList:getSize type_params.type_params) 0)
      (Function:create name.name ret_type.type params.params true)
      (AbstractFunction:create name.name ret_type.type params.params true type_params.type_params)
    );
    this.valid = this.in_interface;
    this.valid2 = (not (TypeParam:isContravariant ret_type.type));

    type_params.symbols_before = (SymbolTable:enterScope this.symbols_before);
    type_params.allow_modifier = false;
    type_params.allow_reified = false;

    name.symbols_before = this.symbols_before;

    params.symbols_before = type_params.symbols_after;

    ret_type.symbols_before = type_params.symbols_after;
    ret_type.required = true;

    this.symbol = .function_symbol;

  }

  func_decl_expr
      ("${inline : OptionalInline}fun ${type_params : OptionalTypeParamters}${name : DefIdentifier}(${params : ParameterDeclarationList})${ret_type : OptionalTypeAnnotation} = ${expr: Expr}") {
    loc function_symbol = (if (== (CustomList:getSize type_params.type_params) 0)
      (Function:create name.name (if ret_type.has_type ret_type.type expr.type) params.params )
      (AbstractFunction:create name.name (if ret_type.has_type ret_type.type expr.type) params.params false type_params.type_params)
    );
    this.valid = true;
    this.valid2 = (not (TypeParam:isContravariant (if ret_type.has_type ret_type.type (SymbolTable:getKotlinAnyType this.symbols_before))));

    inline.in_interface = this.in_interface;

    type_params.symbols_before = (SymbolTable:enterScope this.symbols_before);
    type_params.allow_modifier = false;
    type_params.allow_reified = inline.is_inline;

    name.symbols_before = this.symbols_before;

    params.symbols_before = type_params.symbols_after;

    ret_type.symbols_before = type_params.symbols_after;
    ret_type.required = false;

    expr.symbols_before = params.symbols_after;
    expr.expected_type = (if ret_type.has_type ret_type.type (SymbolTable:getKotlinAnyType this.symbols_before));

    this.symbol = .function_symbol;
  }

  func_decl
      ("${inline : OptionalInline}fun ${type_params : OptionalTypeParamters}${name : DefIdentifier}(${params : ParameterDeclarationList})${ret_type : OptionalTypeAnnotation} {\+
          ${body : FunctionBody}\-
        }\n") {
    loc actual_ret_type = (if ret_type.has_type ret_type.type (SymbolTable:getAsType this.symbols_before "Unit"));
    loc function_symbol = (if (== (CustomList:getSize type_params.type_params) 0)
      (Function:create name.name .actual_ret_type params.params)
      (AbstractFunction:create name.name .actual_ret_type params.params false type_params.type_params)
    );
    this.valid = true;
    this.valid2 = (not (TypeParam:isContravariant .actual_ret_type));

    inline.in_interface = this.in_interface;

    type_params.symbols_before = (SymbolTable:enterScope this.symbols_before);
    type_params.allow_modifier = false;
    type_params.allow_reified = inline.is_inline;

    name.symbols_before = this.symbols_before;

    params.symbols_before = type_params.symbols_after;

    ret_type.symbols_before = type_params.symbols_after;
    ret_type.required = false;

    body.symbols_before = params.symbols_after;
    body.expected_return_type = .actual_ret_type;

    this.symbol = .function_symbol;
  }

}

class OptionalInline {
  grd valid;

  inh in_interface : boolean;

  syn is_inline : boolean;

  no_inline("") {
    this.valid = true;

    this.is_inline = false;
  }

  inline("inline ") {
    this.valid = (not this.in_interface);

    this.is_inline = true;
  }
}

@list(10)
class ParameterDeclarationList {

  syn params : CustomList;
  syn symbols_after : SymbolTable;

  inh symbols_before : SymbolTable;

  one_param ("${param : ParameterDeclaration}") {
    param.symbols_before = this.symbols_before;
    param.is_mutable = false;
    this.symbols_after = (SymbolTable:put this.symbols_before param.symbol);
    this.params = (CustomList:create param.symbol);
  }

  mult_param ("${param : ParameterDeclaration}, ${rest : ParameterDeclarationList}") {
    param.symbols_before = this.symbols_before;
    param.is_mutable = false;
    rest.symbols_before = (SymbolTable:put this.symbols_before param.symbol);
    this.symbols_after = rest.symbols_after;
    this.params = (CustomList:prepend rest.params param.symbol);
  }

}

class ParameterDeclaration {
  grd valid;

  syn symbol : Variable;

  inh symbols_before : SymbolTable;
  inh is_mutable : boolean;

  @copy
  param_decl ("${name : DefIdentifier}: ${type : Type}") {
    this.valid = (not (TypeParam:isCovariant type.type));
    
    name.symbols_before = this.symbols_before;
    type.symbols_before = this.symbols_before;
    this.symbol = (Variable:create name.name type.type true this.is_mutable);
  }

}

class MainDeclaration {
  inh symbols_before : SymbolTable;

  main ("fun main() {\+${body : FunctionBody}\-}\n") {
    body.symbols_before = (SymbolTable:enterScope this.symbols_before);
    body.expected_return_type = (SymbolTable:getAsType this.symbols_before "Unit");
  }
}

class FunctionBody {
  inh symbols_before : SymbolTable;
  inh expected_return_type : Type;

  body ("
      ${stmts : Block}
      ${ret : OptionalReturnStatement}") {

    stmts.symbols_before = this.symbols_before;
    
    ret.symbols_before = stmts.symbols_after;    
    ret.expected_return_type = this.expected_return_type;
  }
}

class Block {
  inh symbols_before : SymbolTable;

  syn symbols_after : SymbolTable;

  block ("${stmts : StmtList}${hash : PrintHash}") {
    stmts.symbols_before = this.symbols_before;

    hash.symbols_before = stmts.symbols_after;

    this.symbols_after = stmts.symbols_after;
  }
}

class PrintHash {
  inh symbols_before : SymbolTable;

  print_hash ("\n println(Objects.hash(${vars: InsertString}))") {
    vars.string = (SymbolTable:getAllVariablesString this.symbols_before);
  }
}

@list(100)
class StmtList {

  inh symbols_before : SymbolTable;

  syn symbols_after : SymbolTable;

  @weight(2)
  one_stmt ("${stmt : Stmt}") {
    stmt.symbols_before = this.symbols_before;
    
    this.symbols_after = stmt.symbols_after;
  }

  @weight(50)
  mult_stmt ("${stmt : Stmt}\n${rest : StmtList}") {
    stmt.symbols_before = this.symbols_before;

    rest.symbols_before = stmt.symbols_after;
    
    this.symbols_after = rest.symbols_after;
  }

}

class Stmt {

  inh symbols_before : SymbolTable;

  syn symbols_after : SymbolTable;

  grd possible;

  @weight(0)
  extension_func ("${extension_func : ExtensionFunctionDeclaration}") {
    this.possible = true;

    extension_func.symbols_before = this.symbols_before;

    this.symbols_after = (SymbolTable:put this.symbols_before (Type:addMemberFunction extension_func.type extension_func.function));
  }

  call ("${call : Call}") {
    this.possible = true;

    call.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);
    call.symbols_before = this.symbols_before;

    this.symbols_after = this.symbols_before;
  }

  member_function_call ("${member_function_call : MemberFunctionCall}") {
    this.possible = true;
    
    member_function_call.symbols_before = this.symbols_before;
    member_function_call.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);

    this.symbols_after = this.symbols_before;
  }

  assign ("${assign : AssignStmt}") {
    this.possible = true;

    assign.symbols_before = this.symbols_before;

    this.symbols_after = assign.symbols_after;
  }

  @weight(0)
  print ("${print : Print}") {
    this.possible = true;

    print.symbols_before = this.symbols_before;
    
    this.symbols_after = this.symbols_before;
  }

  var_decl("${decl : VariableDeclaration}\n") {
    this.possible = true;

    decl.symbols_before = this.symbols_before;
    decl.must_initialise = false;

    this.symbols_after = (SymbolTable:put this.symbols_before decl.symbol);
  }

}

class ExtensionFunctionDeclaration {

  syn function : Function;
  syn type : Type;

  inh symbols_before : SymbolTable;

  func_decl_expr
      ("fun ${type : Type}.${name : DefIdentifier}(${params : ParameterDeclarationList})${ret_type : OptionalTypeAnnotation} = ${expr: Expr}") {
    
    loc this_object = (Variable:create "this" type.type true false);

    type.symbols_before = this.symbols_before;
    this.type = type.type;
    params.symbols_before = (SymbolTable:enterScope this.symbols_before);
    ret_type.symbols_before = this.symbols_before;
    ret_type.required = false;
    expr.symbols_before = (SymbolTable:put (SymbolTable:putAll (SymbolTable:merge this.symbols_before this.symbols_before) params.params) .this_object);
    expr.expected_type = (if ret_type.has_type ret_type.type (SymbolTable:getKotlinAnyType this.symbols_before));
    name.symbols_before = this.symbols_before;
    this.function = (Function:create name.name (if ret_type.has_type ret_type.type expr.type) params.params );
  }

  func_decl
      ("fun ${type : Type}.${name : DefIdentifier}(${params : ParameterDeclarationList})${ret_type : OptionalTypeAnnotation} {\+
          ${body : FunctionBody}\-
        }\n") {
    loc actual_ret_type = (if ret_type.has_type ret_type.type (SymbolTable:getAsType this.symbols_before "Unit"));
    loc this_object = (Variable:create "this" type.type true false);

    type.symbols_before = this.symbols_before;
    this.type = type.type;
    ret_type.symbols_before = this.symbols_before;
    ret_type.required = false;
    params.symbols_before = (SymbolTable:enterScope this.symbols_before);
    body.symbols_before = (SymbolTable:put (SymbolTable:putAll (SymbolTable:merge this.symbols_before this.symbols_before) params.params) .this_object);
    body.expected_return_type = .actual_ret_type;
    name.symbols_before = this.symbols_before;
    this.function = (Function:create name.name .actual_ret_type params.params);
  }
}

class MemberFunctionCall {
  inh symbols_before : SymbolTable;
  inh expected_type : Type;

  syn type : Type;

  member_function_call("${expr : Expr}.${member_function_callee : MemberFunctionCallee}(${args : ArgumentList})") {
    expr.symbols_before = this.symbols_before;
    expr.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);

    member_function_callee.expected_return_type = this.expected_type;
    member_function_callee.callee_type = expr.type;
    member_function_callee.symbols_before = this.symbols_before;

    args.expected_params = (Function:getParams member_function_callee.symbol);
    args.symbols_before = this.symbols_before;

    

    this.type = (Function:getReturnType member_function_callee.symbol);

  }
}

class Call {

  inh symbols_before : SymbolTable;
  inh expected_type : Type;

  syn type : Type;

  call ("${callee : Callee}(${args : ArgumentList})") {
    loc functionSymbol = callee.symbol;

    args.expected_params = (Function:getParams .functionSymbol);
    args.symbols_before = this.symbols_before;

    callee.symbols_before = this.symbols_before;
    callee.expected_return_type = this.expected_type;

    this.type = (Function:getReturnType .functionSymbol);
  }

}

@list
class ArgumentList {

  inh symbols_before : SymbolTable;
  inh expected_params : CustomList;

  grd valid;

  no_arg ("") {
    this.valid = (== (CustomList:getSize this.expected_params) 0);
  }

  one_arg ("${val : Expr}") {
    this.valid = (== (CustomList:getSize this.expected_params) 1);

    val.expected_type = (Variable:getType (CustomList:asVariable (CustomList:getHead this.expected_params)));
    val.symbols_before = this.symbols_before;
  }

  mult_arg ("${val : Expr}, ${rest : ArgumentList}") {
    this.valid = (> (CustomList:getSize this.expected_params) 1);

    val.expected_type = (Variable:getType (CustomList:asVariable (CustomList:getHead this.expected_params)));
    val.symbols_before = this.symbols_before;
    rest.expected_params = (CustomList:getTail this.expected_params);
    rest.symbols_before = this.symbols_before;
  }

}

class MemberFunctionCallee {
  inh expected_return_type : Type;
  inh callee_type : Type;
  inh symbols_before : SymbolTable;

  syn symbol : Function;

  callee ("${member_function : UseMemberFunctionIdentifier}${type_constructor : OptionalFunctionTypeConstructor}") {
    member_function.expected_return_type = this.expected_return_type;
    member_function.callee_type = this.callee_type;
    member_function.symbols_before = this.symbols_before;

    type_constructor.symbols_before = this.symbols_before;
    type_constructor.function_before = member_function.symbol;

    this.symbol = type_constructor.function_after;
  }
}

class Callee {

  inh symbols_before : SymbolTable;
  inh expected_return_type : Type;

  syn symbol : Function;


  callee ("${func : UseFunctionIdentifier}${type_constructor : OptionalFunctionTypeConstructor}") {
    func.expected_return_type = this.expected_return_type;
    func.symbols_before = this.symbols_before;

    type_constructor.symbols_before = this.symbols_before;
    type_constructor.function_before = func.symbol;

    this.symbol = type_constructor.function_after;

  }

}

class OptionalFunctionTypeConstructor {
  grd valid;

  inh symbols_before : SymbolTable;
  inh function_before : Function;

  syn function_after : Function;
  syn symbols_after : SymbolTable;

  no_constructor ("") {
    this.valid = (not (AbstractFunction:isAbstractFunction this.function_before));
    this.function_after = this.function_before; 
    this.symbols_after = this.symbols_before;
  }

  constructor ("<${constructor : FunctionTypeConstructorList}>") {
    loc abstract_function = (AbstractFunction:asAbstractFunction this.function_before);
    loc concrete_function = (AbstractFunction:instantiate .abstract_function constructor.type_arguments);
    this.valid = (AbstractFunction:isAbstractFunction this.function_before);

    constructor.symbols_before = this.symbols_before;
    constructor.type_params = (AbstractFunction:getTypeParams .abstract_function);

    this.function_after = .concrete_function;
    this.symbols_after = (SymbolTable:nothing this.symbols_before (AbstractFunction:addConcreteInstance .abstract_function .concrete_function));
  }
}

class FunctionTypeConstructorList {
  grd valid;
  grd valid2;
  grd valid3;

  inh symbols_before : SymbolTable;
  inh type_params : CustomList;

  syn type_arguments : CustomList;
  
  one ("${type : Type}") {
    loc type_param = (CustomList:asTypeParam (CustomList:getHead this.type_params));
    this.valid = (== (CustomList:getSize this.type_params) 1);
    
    type.symbols_before = this.symbols_before;
    this.valid2 = (not (TypeParam:isReified type.type));
    this.valid3 = (Type:assignable type.type (TypeParam:getUpperbound .type_param));
    
    this.type_arguments = (CustomList:create (Pair:create "inv" type.type));
  }
}

class AssignStmt {

  inh symbols_before : SymbolTable;

  syn symbols_after : SymbolTable;

  grd valid; 

  assign ("${lhs : AssignableExpr} = ${rhs : Expr}") {
    lhs.symbols_before = this.symbols_before;

    this.valid = (Variable:getIsMutable lhs.symbol);

    rhs.expected_type = (Variable:getType lhs.symbol);
    rhs.symbols_before = this.symbols_before;

    this.symbols_after = (if lhs.is_property this.symbols_before (SymbolTable:setIsInitialised this.symbols_before lhs.symbol true));
  }
}

class AssignableExpr {
  inh symbols_before : SymbolTable;

  syn symbol : Variable;
  syn is_property : Boolean;

  @weight(1)
  variable ("${var : UseVariableIdentifier}") {
    var.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);
    var.symbols_before = this.symbols_before;
    this.symbol = var.symbol;
    this.is_property = false;
  }

  @weight(5)
  property ("${class_type : Expr}.${property : UsePropertyIdentifier}") {
    class_type.symbols_before = this.symbols_before;
    class_type.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);
    property.class_type = class_type.type;
    property.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);
    this.symbol = property.symbol;
    this.is_property = true;
  }
}

class VariableDeclaration {

  grd valid;
  
  syn symbol : Variable;

  inh symbols_before : SymbolTable;
  inh must_initialise : boolean;

  var_decl ("${mod: VariableModifier} ${name : DefIdentifier}${type : OptionalTypeAnnotation} ${init : OptionalVariableInitialiation}") {
    type.symbols_before = this.symbols_before;
    type.required = false;
    init.symbols_before = this.symbols_before;
    init.expected_type = type.type;
    init.must_initialise = this.must_initialise;
    init.must_not_initialise = false;
    
    name.symbols_before = this.symbols_before;

    this.valid = (or type.has_type init.is_initialised);

    this.symbol = (Variable:create name.name (if type.has_type type.type init.type) init.is_initialised mod.is_mutable);
  }
}

class DefIdentifier {

  inh symbols_before : SymbolTable;

  syn name : String;

  grd name_unique;

  def_id ("${id : Identifier}") {
    this.name = id.str;
    this.name_unique = (SymbolTable:mayDefine this.symbols_before id.str);
  }

}

@count(1000)
class Identifier("[a-z][a-zA-Z_]{1,7}");

class OptionalVariableInitialiation {
  grd valid;

  inh expected_type : Type;
  inh symbols_before : SymbolTable;
  inh must_initialise : boolean;
  inh must_not_initialise : boolean;
  
  syn is_initialised : boolean;
  syn type : Type;

  no_init("") {
    this.valid = (not this.must_initialise);

    this.is_initialised = false;
    this.type = (SymbolTable:getKotlinAnyType this.symbols_before);
  }

  init("= ${expr : Expr}") {
    this.valid = (not this.must_not_initialise);

    expr.symbols_before = this.symbols_before;
    expr.expected_type = this.expected_type;

    this.is_initialised = true;
    this.type = expr.type;
  }
}

class OptionalTypeAnnotation {
  grd valid;
  inh symbols_before: SymbolTable;
  inh required : boolean;

  syn type : Type;
  syn has_type : boolean;

  no_type_annotation("") {
    this.valid = (not this.required);
    this.type = (SymbolTable:getKotlinAnyType this.symbols_before);
    this.has_type = false;
  }

  type_annotation(": ${type: Type}") {
    this.valid = true;
    type.symbols_before = this.symbols_before;
    this.type = type.type;
    this.has_type = true;
  }
}

class Type {
  inh symbols_before : SymbolTable;

  syn type  : Type;

  type ("${type : UseTypeIdentifier}${type_constructor : OptionalTypeConstructor}") {
    type.symbols_before = this.symbols_before;

    type_constructor.type_before = type.type;
    type_constructor.symbols_before = this.symbols_before;

    this.type = type_constructor.type_after;
  }
}

class OptionalTypeConstructor {
  grd valid;

  inh symbols_before : SymbolTable;
  inh type_before : Type;

  syn type_after : Type;
  syn symbols_after : SymbolTable;

  no_constructor ("") {
    this.valid = (not (AbstractType:isAbstractType this.type_before));
    this.type_after = this.type_before; 
    this.symbols_after = this.symbols_before;
  }

  constructor ("<${constructor : TypeConstructorList}>") {
    loc abstract_type = (AbstractType:asAbstractType this.type_before);
    loc concrete_type = (AbstractType:instantiate .abstract_type constructor.type_arguments);
    this.valid = (AbstractType:isAbstractType this.type_before);

    constructor.symbols_before = this.symbols_before;
    constructor.type_params = (AbstractType:getTypeParams .abstract_type);

    this.type_after = .concrete_type;
    this.symbols_after = (SymbolTable:nothing this.symbols_before (AbstractType:addConcreteInstance .abstract_type .concrete_type));
  }
}

class TypeConstructorList {
  grd valid;
  grd valid2;
  grd valid3;
  grd valid4;
  grd valid5;

  inh symbols_before : SymbolTable;
  inh type_params : CustomList;

  syn type_arguments : CustomList;
  
  one ("${use_site_mod : OptionalVarianceModifier}${type : Type}") {
    loc type_param = (CustomList:asTypeParam (CustomList:getHead this.type_params));
    loc actual_variance = (if (TypeParam:isInvariant .type_param) use_site_mod.modifier (TypeParam:getVariance .type_param));
    this.valid = (== (CustomList:getSize this.type_params) 1);
    this.valid2 = (not (and (TypeParam:isCovariant .type_param) (TypeParam:isContravariant type.type)));
    this.valid3 = (not (and (TypeParam:isContravariant .type_param) (TypeParam:isCovariant type.type)));

    use_site_mod.allow_modifier = (TypeParam:isInvariant .type_param);
    
    type.symbols_before = this.symbols_before;
    this.valid4 = (not (TypeParam:isReified type.type));
    this.valid5 = (Type:assignable type.type (TypeParam:getUpperbound .type_param));
    
    this.type_arguments = (CustomList:create (Pair:create .actual_variance type.type));
  }
}

class TypeCheckType {
  inh symbols_before : SymbolTable;
  inh lhs_type : Type;

  type (SymbolTable:visibleTypeCheckTypes this.symbols_before this.lhs_type) : Type {}
}

class UseTypeIdentifier {
  inh symbols_before : SymbolTable;

  syn type : Type;

  type (SymbolTable:visibleTypes this.symbols_before) : Type {
    this.type = $;
  }
}

class VariableModifier {
  syn is_mutable : boolean;

  var("var") {
    this.is_mutable = true;
  }

  val("val") {
    this.is_mutable = false;
  }
}

class OptionalTypeUpperBound {
  grd valid;
  inh symbols_before: SymbolTable;
  inh required : boolean;

  syn type : Type;
  syn has_type : boolean;

  @weight(4)
  no_type_annotation("") {
    this.valid = (not this.required);
    this.type = (SymbolTable:getKotlinAnyType this.symbols_before);
    this.has_type = false;
  }

  @weight(0)
  type_annotation(": ${type: Type}") {
    this.valid = true;
    type.symbols_before = this.symbols_before;
    this.type = type.type;
    this.has_type = true;
  }
}

class Print {
  inh symbols_before : SymbolTable;

  print ("print (${expr: Expr})") {
    expr.symbols_before = this.symbols_before;
    expr.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);
  }
}

class OptionalReturnStatement {
  grd valid;

  inh symbols_before : SymbolTable;
  inh expected_return_type : Type;

  no_ret ("") {
    this.valid = (Type:isUnitType this.expected_return_type);
  }

  ret ("\n${ret : ReturnStatement}") {
    this.valid = true;
    ret.symbols_before = this.symbols_before;
    ret.expected_return_type = this.expected_return_type;
  }

}

class ReturnStatement {
  grd valid;

  inh symbols_before : SymbolTable;
  inh expected_return_type : Type;

  ret_void ("return") {
    this.valid = (Type:isUnitType this.expected_return_type);
  }

  ret_val ("return ${val : Expr}") {
    this.valid = (not (Type:isUnitType this.expected_return_type));

    val.expected_type = this.expected_return_type;
    val.symbols_before = this.symbols_before;
  }
}

@max_height(8)
class Expr {
  inh symbols_before : SymbolTable;
  inh expected_type : Type;

  syn type : Type;

  grd valid;
  grd valid2;

  @weight(10)
  atom ("${atom : ExprAtom}") {
    this.valid = true;
    this.valid2 = true;

    atom.symbols_before = this.symbols_before;
    atom.expected_type = this.expected_type;

    this.type = atom.type;
  }


  member_function_call ("${member_function_call : MemberFunctionCall}") {
    this.valid = true;
    this.valid2 = true;

    member_function_call.symbols_before = this.symbols_before;
    member_function_call.expected_type = this.expected_type;

    this.type = member_function_call.type;
  }

  type_check ("(${expr : Expr} ${op : TypeCheckOperator} ${type : TypeCheckType})") {
    loc bool_type = (SymbolTable:getAsType this.symbols_before "Boolean");
    this.valid = (Type:assignable .bool_type this.expected_type);
    this.valid2 = true;

    expr.symbols_before = this.symbols_before;
    expr.expected_type = (SymbolTable:getAsType this.symbols_before "Any");

    type.symbols_before = this.symbols_before;
    type.lhs_type = expr.type;

    this.type = .bool_type;
  }

  arith_bin_op ("((${lhs : Expr}) ${op : ArithBinaryOperator} (${rhs : Expr}))") {
    loc int_type = (SymbolTable:getAsType this.symbols_before "Int");
    this.valid2 = true;

    lhs.symbols_before = this.symbols_before;
    lhs.expected_type = .int_type;

    rhs.symbols_before = this.symbols_before;
    rhs.expected_type = .int_type;

    this.valid = (Type:assignable .int_type this.expected_type);
    this.type = .int_type;
  }

  bool_bin_op ("((${lhs : Expr}) ${op : BoolBinaryOperator} (${rhs : Expr}))") {
    loc bool_type = (SymbolTable:getAsType this.symbols_before "Boolean");
    this.valid2 = true;

    lhs.symbols_before = this.symbols_before;
    lhs.expected_type = .bool_type;

    rhs.symbols_before = this.symbols_before;
    rhs.expected_type = .bool_type;

    this.valid = (Type:assignable .bool_type this.expected_type);
    this.type = .bool_type;
  }

  bool_unary_op ("(${op: BoolUnaryOperator}(${exp: Expr}))") {
    loc bool_type = (SymbolTable:getAsType this.symbols_before "Boolean");
    this.valid2 = true;

    exp.symbols_before = this.symbols_before;
    exp.expected_type = .bool_type;

    this.valid = (Type:assignable .bool_type this.expected_type);
    this.type = .bool_type;
  }

  equality_bin_op ("((${lhs : Expr}) ${op : EqualityOp} (${rhs : Expr}))") {
    this.valid2 = true;

    lhs.symbols_before = this.symbols_before;
    lhs.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);

    rhs.symbols_before = this.symbols_before;
    rhs.expected_type = lhs.type;

    this.valid = (Type:assignable (SymbolTable:getAsType this.symbols_before "Boolean") this.expected_type);
    this.type = (SymbolTable:getAsType this.symbols_before "Boolean");
  }

  comparison_bin_op ("((${lhs: Expr}) ${op : ComparisonOp} (${rhs : Expr}))") {
    lhs.symbols_before = this.symbols_before;
    lhs.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);
    
    this.valid2 = true;

    rhs.symbols_before = this.symbols_before;
    rhs.expected_type = lhs.type;

    this.valid = (and (Type:assignable (SymbolTable:getAsType this.symbols_before "Boolean") this.expected_type) false);
    this.type = (SymbolTable:getAsType this.symbols_before "Boolean");
  }
}

class TypeCheckOperator("is|!is");

class ArithBinaryOperator("+|-|*|/|%");

class BoolBinaryOperator("&&|[|][|]");

class BoolUnaryOperator("!");

class EqualityOp("==|!=");

class ComparisonOp(">|>=|<|<=");

class ExprAtom {
  inh symbols_before : SymbolTable;
  inh expected_type : Type;

  grd valid;

  syn type : Type;

  call ("${call : Call}") {
    this.valid = true;
    call.expected_type = this.expected_type;
    call.symbols_before = this.symbols_before;

    this.type = call.type;
  }

  property ("${ident : UseVariableIdentifier}.${property : UsePropertyIdentifier}") {
    this.valid = (Variable:getIsInitialised ident.symbol);

    ident.symbols_before = this.symbols_before;
    ident.expected_type = (SymbolTable:getKotlinAnyType this.symbols_before);

    property.class_type = (Variable:getType ident.symbol);
    property.expected_type = this.expected_type;
    this.type = (Variable:getType property.symbol);
  }


  num ("${val : Number}") {
    this.valid = true;
    
    val.symbols_before = this.symbols_before;
    val.expected_type = this.expected_type;
    this.type = val.type;
  }

  string_literal ("${str: StringLiteral}") {
    loc type = (SymbolTable:getAsType this.symbols_before "String");
    this.valid = (Type:assignable .type this.expected_type);

    this.type = .type;
  }

  boolean_literal ("${bool: BooleanLiteral}") {
    loc type = (SymbolTable:getAsType this.symbols_before "Boolean");
    this.valid = (Type:assignable .type this.expected_type);

    this.type = .type;
  }

  char_literal ("${char: CharLiteral}") {
    loc type = (SymbolTable:getAsType this.symbols_before "Char");
    this.valid = (Type:assignable .type this.expected_type);

    this.type = .type;
  }

  var ("${name : UseVariableIdentifier}") {  
    loc type = (Variable:getType name.symbol);
    name.symbols_before = this.symbols_before;
    name.expected_type = this.expected_type;

    this.type = .type;

    this.valid = (Variable:getIsInitialised name.symbol);
  }

}

class BooleanLiteral("false|true");

class StringLiteral("\"[a-zA-Z0-9]{0,15}\"");

class CharLiteral("\'[a-zA-Z0-9]\'");

class UseVariableIdentifier {

  inh symbols_before : SymbolTable;
  inh expected_type : Type;

  syn symbol : Variable;

  use_id (SymbolTable:visibleVariables this.symbols_before this.expected_type) : Variable {
    this.symbol = $;
  }

}

class InsertString {
  inh string : String;

  string (GeneratorClassHelper:singleString this.string) : String {}
}

class UsePropertyIdentifier {

  inh expected_type : Type;
  inh class_type : Type;

  syn symbol : Variable;

  use_id (SymbolTable:visibleProperties this.class_type this.expected_type) : Variable {
    this.symbol = $;
  }
}

class UseFunctionIdentifier {

  inh symbols_before : SymbolTable;
  inh expected_return_type : Type;

  syn symbol : Function;

  use_id (SymbolTable:visibleFunctions this.symbols_before this.expected_return_type) : Function {
    this.symbol = $;
  }

}

class UseMemberFunctionIdentifier {

  inh expected_return_type : Type;
  inh callee_type : Type;
  inh symbols_before : SymbolTable;

  syn symbol : Function;

  use_id (SymbolTable:visibleMemberFunctions this.callee_type this.symbols_before this.expected_return_type) : Function {
    this.symbol = $;
  }

}

class Number {
  inh symbols_before : SymbolTable;
  inh expected_type : Type;
  syn type : Type;

  grd type_matches;

  int_number ("${num : IntNumber}") {
    loc type = (SymbolTable:getAsType this.symbols_before "Int");
    this.type_matches = (Type:assignable .type this.expected_type);
    this.type = .type;
  }
}

class IntNumber("0|[1-9][0-9]{0,8}");