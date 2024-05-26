package runtime;

import java.util.List;
import java.util.ArrayList;

import i2.act.fuzzer.runtime.Printable;

public class AbstractFunction extends Function {

  public final CustomList<TypeParam> typeParams;
  public final CustomList<Function> concreteInstances;

  public AbstractFunction(String name, Type returnType, CustomList<Variable> params, boolean isAbstract,
    CustomList<Pair<String, Type>> typeArguments, CustomList<TypeParam> typeParams, CustomList<Function> concreteInstances) {
  
    super(name, returnType, params, isAbstract, typeArguments);
    this.typeParams = typeParams;
    this.concreteInstances = concreteInstances;
  }

  public static Function create(String name, Type returnType, CustomList<Variable> params, boolean isAbstract,
    CustomList<TypeParam> typeParams) {
      return new AbstractFunction(name, returnType, params, isAbstract, new CustomList<>(), typeParams, new CustomList<>());
  }

  public static boolean isAbstractFunction(Function function) {
    return function instanceof AbstractFunction;
  }

  public static AbstractFunction asAbstractFunction(Function function) {
    if (!(function instanceof AbstractFunction)) {
      throw new RuntimeException("Tried to cast non abstract function into an abstract function");
    }
    return (AbstractFunction) function;
  }

  public static CustomList<TypeParam> getTypeParams(AbstractFunction function) {
    return function.typeParams;
  }

  public static AbstractFunction addConcreteInstance(AbstractFunction abstractFunction, Function concreteFunction) {
    abstractFunction.concreteInstances.add(concreteFunction);
    return abstractFunction;
  }

  public static Function instantiate(AbstractFunction abstractFunction, CustomList<Pair<String, Type>> typeArguments) {

    StringBuilder sb = new StringBuilder();
    sb.append(abstractFunction.name);
    sb.append("<");
    boolean first = true;
    for (int i = 0; i < typeArguments.items.size(); i++) {
      Pair<String, Type> typeArgument = typeArguments.items.get(i);
      TypeParam typeParam = abstractFunction.typeParams.items.get(i);
      if (!first) {
        sb.append(", ");
        first = false;
      }
      sb.append(typeArgument.second.name);
    }
    sb.append(">");

    List<Variable> concreteParameters = new ArrayList<>();
    for (Variable abstractParameter : abstractFunction.params.items) {
      Variable concreteParameter = abstractParameter.clone();
      int index = abstractFunction.typeParams.indexOf(concreteParameter.type);
      if (index != -1) {
        concreteParameter.type = typeArguments.items.get(index).second;
      }
      concreteParameters.add(concreteParameter);
    }

    Type concreteReturnType;
    int index = abstractFunction.typeParams.indexOf(abstractFunction.returnType);
    if (index != -1) {
      concreteReturnType = typeArguments.items.get(index).second;
    } else {
      concreteReturnType = abstractFunction.returnType;
    }

    return new Function(sb.toString(), concreteReturnType, new CustomList<>(concreteParameters), abstractFunction.isAbstract, typeArguments); 
  }

  @Override 
  public AbstractFunction clone() {
    return new AbstractFunction(name, returnType, params.clone(), isAbstract, typeArguments, typeParams, concreteInstances);
  }
}
