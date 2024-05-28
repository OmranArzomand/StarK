package runtime;

import i2.act.fuzzer.runtime.Printable;

import java.util.Objects;

public class Variable extends Symbol implements Printable {
  public Type type;
  public final boolean isInitialised;
  public final boolean isMutable;
  public final boolean isAbstract;

  public Variable(String name, Type type, boolean isInitialised, boolean isMutable) {
    super(name);
    this.type = type;
    this.isInitialised = isInitialised;
    this.isMutable = isMutable;
    this.isAbstract = false;
  }

  public Variable(String name, Type type, boolean isInitialised, boolean isMutable, boolean isAbstract) {
    super(name);
    this.type = type;
    this.isInitialised = isInitialised;
    this.isMutable = isMutable;
    this.isAbstract = isAbstract;
  }

  public static final Variable create(String name, Type type, boolean isInitialised, boolean isMutable) {
    return new Variable(name, type, isInitialised, isMutable);
  }

  public static final Variable create(String name, Type type, boolean isInitialised, boolean isMutable, boolean isAbstract) {
    return new Variable(name, type, isInitialised, isMutable, isAbstract);
  }

  public static final Type getType(Variable variable) {
    return variable.type;
  }

  public static final String getName(Variable variable) {
    return variable.name;
  }

  public static final boolean getIsMutable(Variable variable) {
    return variable.isMutable;
  }

  public static final boolean getIsInitialised(Variable variable) {
    return variable.isInitialised;
  }

  @Override
  public Variable clone() {
    return new Variable(name, type, isInitialised, isMutable, isAbstract);
  }

  @Override
  public boolean equals(Object obj) {
    if (!(obj instanceof Variable)) {
      return false;
    }

    final Variable otherVariable = (Variable) obj;

    return Objects.equals(this.name, otherVariable.name);
  }

  @Override
  public int hashCode() {
    return Objects.hash(this.name, this.type, this.isInitialised, this.isMutable);
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
