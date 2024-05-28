package runtime;

import i2.act.fuzzer.runtime.Printable;

public class TypeParam extends Type {

  public final String variance;
  public final boolean isReified;
  public final Type upperbound;

  public TypeParam(String name, String variance, boolean isReified, Type upperbound, CustomList<Type> supertypes) {
    super(name, false, false, new CustomList<>(), new CustomList<>(), supertypes);
    this.variance = variance;
    this.isReified = isReified;
    this.upperbound = upperbound;
  }

  public TypeParam(String name, boolean isInterface, boolean isOpen, CustomList<CustomList<Variable>> constructors, 
  CustomList<Function> memberFunctions, CustomList<Variable> properties, CustomList<Type> supertypes,
  CustomList<Pair<String, Type>> typeArguments, String variance, Boolean isReified, Type upperbound) {
    super(name, isInterface, isOpen, constructors, memberFunctions, properties, supertypes, typeArguments);
    this.variance = variance;
    this.isReified = isReified;
    this.upperbound = upperbound;
  }

  public static TypeParam create(String name, String variance, boolean isReified, Type upperbound, CustomList<Type> supertypes) {
    return new TypeParam(name, variance, isReified, upperbound, supertypes);
  }

  public static String getVariance(TypeParam typeParam) {
    return typeParam.variance;
  }

  public static Type getUpperbound(TypeParam typeParam) {
    return typeParam.upperbound;
  }

  public static boolean isInvariant(TypeParam typeParam) {
    return typeParam.variance.equals("inv");
  }

  public static boolean isContravariant(Type type) {
    if (!(type instanceof TypeParam)) {
      return false;
    }
    TypeParam typeParam = (TypeParam) type;
    return typeParam.variance.equals("in");
  }

  public static boolean isCovariant(Type type) {
    if (!(type instanceof TypeParam)) {
      return false;
    }
    TypeParam typeParam = (TypeParam) type;
    return typeParam.variance.equals("out");
  }

  public static boolean isReified(Type type) {
    if (!(type instanceof TypeParam)) {
      return false;
    }
    TypeParam typeParam = (TypeParam) type;
    return typeParam.isReified;
  }

  @Override
  public TypeParam clone() {
    return new TypeParam(name, isInterface, isOpen, constructors.clone(), memberFunctions.clone(), properties.clone(), supertypes, typeArguments, variance, isReified, upperbound);
  }
}
