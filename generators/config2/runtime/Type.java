package runtime;

import i2.act.fuzzer.runtime.Printable;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.ArrayList;
import java.util.Set;
import java.util.HashSet;

public class Type extends Symbol implements Printable{
  public final boolean isOpen;
  public final boolean isInterface;
  public final CustomList<CustomList<Variable>> constructors;
  public final CustomList<Function> memberFunctions;
  public final CustomList<Variable> properties;
  public final CustomList<Type> supertypes;
  public final CustomList<Pair<String, Type>> typeArguments;

  public Type(String name, CustomList<CustomList<Variable>> constructors) {
    super(name);
    this.isInterface = false;
    this.isOpen = false;
    this.constructors = constructors;
    this.memberFunctions = new CustomList<>();
    this.properties = new CustomList<>();
    this.supertypes = new CustomList<>();
    this.typeArguments = new CustomList<>();
  }

  public Type(String name, boolean isInterface, boolean isOpen, CustomList<CustomList<Variable>> constructors, 
    CustomList<Variable> properties, CustomList<Type> supertypes) {
    super(name);
    this.isInterface = isInterface;
    this.isOpen = isOpen;
    this.constructors = constructors;
    this.memberFunctions = new CustomList<>();
    this.properties = properties;
    this.supertypes = supertypes;
    this.typeArguments = new CustomList<>();
  }


  public Type(String name, boolean isInterface, boolean isOpen, CustomList<CustomList<Variable>> constructors, 
    CustomList<Function> memberFunctions, CustomList<Variable> properties, CustomList<Type> superTypes,
    CustomList<Pair<String, Type>> typeArguments) {
      super(name);
      this.isInterface = isInterface;
      this.isOpen = isOpen;
      this.constructors = constructors;
      this.memberFunctions = memberFunctions;
      this.properties = properties;
      this.supertypes = superTypes;
      this.typeArguments = typeArguments;
    }

  public Type(String name) {
    super(name);
    this.isInterface = false;
    this.isOpen = false;
    this.constructors = new CustomList<>();
    this.memberFunctions = new CustomList<>();
    this.properties = new CustomList<>();
    this.supertypes = new CustomList<>();
    this.typeArguments = new CustomList<>();
  }

  @Override
  public Type clone() {
    return new Type(name, isInterface, isOpen, constructors.clone(), memberFunctions.clone(), properties.clone(), supertypes, typeArguments);
  }


  public static final boolean assignable(final Type sourceType, final Type targetType) {
    String sourceClassName = sourceType.name.split("<")[0];  
    String targetClassName = targetType.name.split("<")[0];  

    if (!sourceClassName.equals(targetClassName)) {
      for (Type t : sourceType.supertypes.items) {
        if (assignable(t, targetType)) {
          return true;
        }
      }
      return false;
    }

    if (!(sourceType.typeArguments.items.size() == targetType.typeArguments.items.size())) {
      System.out.println("XXXXXXXXXXX WENT BAD XXXXXXXXXXXX");
      return false;
    }
    assert(sourceType.typeArguments.items.size() == targetType.typeArguments.items.size());

    for (int i = 0; i < sourceType.typeArguments.items.size(); i++) {
      Pair<String, Type> sourceTypeArg = sourceType.typeArguments.items.get(i);
      Pair<String, Type> targetTypeArg = targetType.typeArguments.items.get(i);
      if (targetTypeArg.first.equals("inv")) {
        if (sourceTypeArg.first.equals("inv")) {
          return sourceTypeArg.second.name.equals(targetTypeArg.second.name);
        } else {
          return false;
        }
      } else if (targetTypeArg.first.equals("in")) {
        if (sourceTypeArg.first.equals("out")) {
          return false;
        } else {
          return assignable(targetTypeArg.second, sourceTypeArg.second);
        }
      } else {
        if (sourceTypeArg.first.equals("in")) {
          return false;
        } else {
          return assignable(sourceTypeArg.second, targetTypeArg.second);
        }
      }
    }
    return true;
  }

  public static boolean containsNoClasses(CustomList<Type> types) {
    for (Type type : types.items) {
      if (!type.isInterface) {
        return false;
      }
    }
    return true;
  }

  public static boolean isUnitType(Type type) {
    return type.name.equals("Unit");
  }

  public static boolean isInterface(Type type) {
    return type.isInterface;
  }

  public static Type addMemberFunction(Type type, Function function) {
    Type clone = type.clone();
    clone.memberFunctions.add(function);
    return clone;
  }

  public static Type addProperty(Type type, Variable property) {
    Type clone = type.clone();
    clone.properties.add(property);
    return clone;
  }

  public static Type addSupertype(Type type, Type superType) {
    Type clone = type.clone();
    clone.supertypes.add(superType);
    return clone;
  }

  public static Type addConstrcutor(Type type, CustomList<Variable> constructor) {
    Type clone = type.clone();
    clone.constructors.add(constructor);
    return clone;
  }

  public static String getName(Type type) {
    return type.name;
  }

  public static CustomList<Function> getAbstractMemberFunctions(Type type) {
    Set<Type> visitedTypes = new HashSet<>();
    List<Type> queue = new ArrayList<>();
    for (Type supertype : type.supertypes.items) {
      if (supertype.isInterface) {
        queue.add(supertype);
      }
    }
    List<Function> abstractFunctions = new ArrayList<>();

    while (!queue.isEmpty()) {
      Type curType = queue.remove(0);
      visitedTypes.add(curType);
      for (Type supertype : curType.supertypes.items) {
        if (supertype.isInterface && !visitedTypes.contains(supertype)) {
          queue.add(supertype);
        }
      }
      for (Function function : curType.memberFunctions.items) {
        if (function.isAbstract) {
          abstractFunctions.add(function);
        }
      }     
    }
    return new CustomList<>(abstractFunctions);
  }

  public static CustomList<Variable> getAbstractProperties(Type type) {
    Set<Type> visitedTypes = new HashSet<>();
    List<Type> queue = new ArrayList<>();
    for (Type supertype : type.supertypes.items) {
      if (supertype.isInterface) {
        queue.add(supertype);
      }
    }
    List<Variable> abstractProperties = new ArrayList<>();

    while (!queue.isEmpty()) {
      Type curType = queue.remove(0);
      visitedTypes.add(curType);
      for (Type supertype : curType.supertypes.items) {
        if (supertype.isInterface && !visitedTypes.contains(supertype)) {
          queue.add(supertype);
        }
      }
      for (Variable property : curType.properties.items) {
        if (property.isAbstract) {
          abstractProperties.add(property);
        }
      }     
    }
    return new CustomList<>(abstractProperties);
  }

  public static Function getMemberFunctionWithType(Type type, String name, Type expectedType) {
    for (Function func : type.memberFunctions.items) {
      if (func.name.equals(name) && Type.assignable(func.returnType, expectedType)) {
        return func;
      }
    }
    throw new RuntimeException("Couldn't find function with specified name and return type");
  }

  public static Variable getProperty(Type type, String name) {
    for (Variable property : type.properties.items) {
      if (property.name.equals(name)) {
        return property;
      }
    }
    throw new RuntimeException("Couldn't find property with specified name");
  }

  public static CustomList<CustomList<Variable>> getConstructors(Type type) {
    return type.constructors;
  }

  public static Type create(String name) {
    return new Type(name, CustomList.empty());
  }

  public static Type create(String name, CustomList<CustomList<Variable>> constructors) {
    return new Type(name, constructors);
  }

  public static Type create(String name, boolean isInterface, boolean isOpen, CustomList<CustomList<Variable>> constructors, CustomList<Variable> properties, CustomList<Type> supertypes) {
    return new Type(name, isInterface, isOpen, constructors, properties, supertypes);
  }

  @Override
  public boolean equals(Object obj) {
    if (!(obj instanceof Type)) {
      return false;
    }

    final Type otherType = (Type) obj;

    return Objects.equals(this.name, otherType.name);
  }

  @Override
  public int hashCode() {
    return Objects.hash(this.name);
  }

  @Override
  public final String toString() {
    return String.format("(%s)", this.name);
  }

  @Override
  public final String print() {
    return this.name;
  }
}
