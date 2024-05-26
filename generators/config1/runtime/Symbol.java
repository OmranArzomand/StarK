package runtime;

import i2.act.fuzzer.runtime.Printable;

import java.util.Objects;


public class Symbol implements Printable, Cloneable {

  public final String name;

  public Symbol(String name) {
    this.name = name;
  }

  @Override
  public Symbol clone() {
    return new Symbol(name);
  }

  public static final String getName(final Symbol symbol) {
    return symbol.name;
  }

  public static final Function asFunction(final Symbol symbol) {
    if (symbol instanceof Type) {
      Type type = (Type) symbol;
      if (type.constructors.items.size() == 0) {
        throw new RuntimeException("Invalid cast of Type with no constructor to Function");
      }
      int randomIndex = (int) (Math.random() * type.constructors.items.size());
      CustomList<Variable> params = type.constructors.items.get(randomIndex);
      return Function.create(type.name, type, params);
    }
    if (symbol instanceof Function) {
      return (Function) symbol;
    }
    throw new RuntimeException("Invalid cast of Symbol to Function");
  }

  public static final Variable asVariable(final Symbol symbol) {
    if (!(symbol instanceof Variable)) {
      throw new RuntimeException("Invalid cast of Symbol to Variable");
    }
    return (Variable) symbol;
  }

  @Override
  public boolean equals(Object obj) {
    if (!(obj instanceof Symbol)) {
      return false;
    }
    return Objects.equals(this.name, ((Symbol) obj).name);
  }

  @Override
  public int hashCode() {
    return Objects.hash(this.name);
  }

  @Override
  public String toString() {
    return String.format("(%s)", this.name);
  }

  @Override
  public String print() {
    return this.name;
  }
}