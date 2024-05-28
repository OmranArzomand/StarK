package runtime;

import java.util.List;
import java.util.ArrayList;

import i2.act.fuzzer.runtime.Printable;

public class AbstractType extends Type {
  public final CustomList<TypeParam> typeParams;
  public final CustomList<Type> concreteInstances;

  public AbstractType(String name, boolean isInterface, boolean isOpen, CustomList<CustomList<Variable>> constructors, 
    CustomList<Function> memberFunctions, CustomList<Variable> properties, CustomList<Type> supertypes, 
    CustomList<Pair<String, Type>> typeArguments, CustomList<TypeParam> typeParams, CustomList<Type> concreteInstances) {
    super(name, isInterface, isOpen, constructors, memberFunctions, properties, supertypes, typeArguments);
    this.typeParams = typeParams;
    this.concreteInstances = concreteInstances;
  }

  public static Type create(String name, boolean isInterface, boolean isOpen, CustomList<CustomList<Variable>> constructors, 
  CustomList<Variable> properties, CustomList<Type> supertypes, CustomList<TypeParam> typeParams) {
    return new AbstractType(name, isInterface, isOpen, constructors, new CustomList<>(), properties, supertypes, new CustomList<>(), typeParams, new CustomList<>());
  }

  public static boolean isAbstractType(Type type) {
    return type instanceof AbstractType;
  }

  public static AbstractType asAbstractType(Type type) {
    if (!(type instanceof AbstractType)) {
      throw new RuntimeException("Tried to cast non abstract type into an abstract type");
    }
    return (AbstractType) type;
  }

  public static CustomList<TypeParam> getTypeParams(AbstractType type) {
    return type.typeParams;
  }

  public static AbstractType addConcreteInstance(AbstractType abstractType, Type concreteType) {
    abstractType.concreteInstances.add(concreteType);
    return abstractType;
  }

  public static Type instantiate(AbstractType type, CustomList<Pair<String, Type>> typeArguments) {
    List<Type> useSiteCovariantTypes = new ArrayList<>();
    List<Type>useSiteContravaraintTypes = new ArrayList<>();

    StringBuilder sb = new StringBuilder();
    sb.append(type.name);
    sb.append("<");
    boolean first = true;
    for (int i = 0; i < typeArguments.items.size(); i++) {
      Pair<String, Type> typeArgument = typeArguments.items.get(i);
      TypeParam typeParam = type.typeParams.items.get(i);
      if (!first) {
        sb.append(", ");
        first = false;
      }
      if (!(typeParam.variance.equals(typeArgument.first))) {
        // use site variance occured
        if (typeArgument.first.equals("in")) {
          useSiteContravaraintTypes.add(typeParam);
        } else {
          useSiteCovariantTypes.add(typeParam);
        }
        sb.append(typeArgument.first);
        sb.append(" ");
      }
      sb.append(typeArgument.second.name);
    }

    sb.append(">");
    List<Function> concreteFunctions = new ArrayList<>();
    for (Function abstractFunction : type.memberFunctions.items) {
      boolean valid = true;
      if (useSiteContravaraintTypes.contains(abstractFunction.returnType)) {
        valid = false;
      }
      for (Variable param : abstractFunction.params.items) {
        if (useSiteCovariantTypes.contains(param.type)) {
          valid = false;
        }
      }
      if (!valid) {
        continue;
      }
      if (abstractFunction instanceof AbstractFunction) {
        AbstractFunction a =  (AbstractFunction) abstractFunction;
        a.concreteInstances.items.clear();
      }
      Function concreteFunction = abstractFunction.clone();
      {
        int index = type.typeParams.indexOf(concreteFunction.returnType);
        if (index != -1) {
          concreteFunction.returnType = typeArguments.items.get(index).second;
        }
      }
      for (Variable param : concreteFunction.params.items) {
        int index = type.typeParams.indexOf(param.type);
        if (index != -1) {
          param.type = typeArguments.items.get(index).second;
        }
      }
      if (abstractFunction instanceof AbstractFunction) {
        AbstractFunction f = (AbstractFunction) abstractFunction;
        f.concreteInstances.items.clear();
      }
      concreteFunctions.add(concreteFunction);
    }

    List<CustomList<Variable>> concreteConstructors = new ArrayList<>();
    for (CustomList<Variable> abstractConstructor : type.constructors.items) {
      boolean valid = true;
      for (Variable param : abstractConstructor.items) {
        if (useSiteCovariantTypes.contains(param.type)) {
          valid = false;
        }
      }
      if (!valid) {
        continue;
      }
      CustomList<Variable> concreteConstructor = abstractConstructor.clone();
      for (Variable param : concreteConstructor.items) {
        int index = type.typeParams.indexOf(param.type);
        if (index != -1) {
          param.type = typeArguments.items.get(index).second;
        }
      }
      concreteConstructors.add(concreteConstructor);
    }
    if (useSiteContravaraintTypes.size() != 0 || useSiteCovariantTypes.size() != 0) {
      concreteConstructors = new ArrayList<>();
    }
    List<Variable> concreteProperties = new ArrayList<>();
    for (Variable abstractProperty : type.properties.items) {
      boolean valid = true;
      if (useSiteContravaraintTypes.contains(abstractProperty.type) 
          || (abstractProperty.isMutable && useSiteCovariantTypes.contains(abstractProperty.type))) {
        valid = false;
      }
      if (!valid) {
        continue;
      }
      Variable concreteProperty = abstractProperty.clone();
      int index = type.typeParams.indexOf(concreteProperty.type);
      if (index != -1) {
        concreteProperty.type = typeArguments.items.get(index).second;
      }
      concreteProperties.add(concreteProperty);
    }

    return new Type(sb.toString(), type.isInterface, type.isOpen, new CustomList<>(concreteConstructors), new CustomList<>(concreteFunctions), new CustomList<>(concreteProperties), type.supertypes.clone(), typeArguments);   
  }

  @Override 
  public AbstractType clone() {
    return new AbstractType(name, isInterface, isOpen, constructors.clone(), memberFunctions.clone(), properties.clone(), supertypes, typeArguments, typeParams, concreteInstances);
  }
}
