package runtime;

import i2.act.fuzzer.runtime.Printable;
import java.util.Objects;
import java.util.List;
import java.util.ArrayList;

public class Function extends Symbol implements Printable {

  public Type returnType;
  public final CustomList<Variable> params;
  public final boolean isAbstract;
  public final CustomList<Pair<String, Type>> typeArguments;

  public Function(String name, Type returnType, CustomList<Variable> params) {
    super(name);
    this.returnType = returnType;
    this.params = params;
    this.isAbstract = false;
    this.typeArguments = new CustomList<>();
  }

  public Function(String name, Type returnType, CustomList<Variable> params, boolean isAbstract) {
    super(name);
    this.returnType = returnType;
    this.params = params;
    this.isAbstract = isAbstract;
    this.typeArguments = new CustomList<>();
  }

  public Function(String name, Type returnType, CustomList<Variable> params, boolean isAbstract, CustomList<Pair<String, Type>> typeArguments) {
    super(name);
    this.returnType = returnType;
    this.params = params;
    this.isAbstract = isAbstract;
    this.typeArguments = typeArguments;
  }

  @Override
  public Function clone() {
    return new Function(name, returnType, params.clone(), isAbstract, typeArguments);
  }

  public static Function create(String name, Type returnType, CustomList<Variable> params) {
    return new Function(name, returnType, params, false);
  }

  public static Function create(String name, Type returnType, CustomList<Variable> params, boolean isAbstract) {
    return new Function(name, returnType, params, isAbstract);
  }

  public static CustomList<Variable> getParams(Function function) {
    return function.params;
  }

  public static Type getReturnType(Function function) {
    return function.returnType;
  }

  public static String getName(Function function) {
    return function.name;
  }

  public static boolean paramsClash(CustomList<CustomList<Variable>> listOfParams, CustomList<Variable> params) {
    for (CustomList<Variable> otherParams : listOfParams.items) {
      if (params.items.size() != otherParams.items.size()) {
        continue;
      }
      boolean hasDifferentSignature = false;
      for (int i = 0; i < params.items.size(); i++) {
        Variable param = params.items.get(i);
        Variable otherParam = otherParams.items.get(i);
        if (!Type.assignable(param.type, otherParam.type)) {
          //params different
          hasDifferentSignature = true;
          break;
        }
      }
      if (!hasDifferentSignature) {
        System.out.println("clash ");
        for (Variable p : params.items) {
          System.out.print(" " + p.type);
        }
        System.out.println();
        for (Variable p : otherParams.items) {
          System.out.print(" " + p.type);
        }
        return true;
      }
    }
    return false;
  }

  @Override
  public boolean equals(Object obj) {
    if (!(obj instanceof Function)) {
      return false;
    }

    final Function otherFunction = (Function) obj;

    return Objects.equals(this.name, otherFunction.name)
      && Objects.equals(this.returnType, otherFunction.returnType)
      && Objects.equals(this.params, otherFunction.params);
  }

  @Override
  public int hashCode() {
    return Objects.hash(this.name, this.returnType, this.params);
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
