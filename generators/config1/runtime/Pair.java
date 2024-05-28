package runtime;

import i2.act.fuzzer.runtime.Printable;

import java.util.Objects;

public class Pair<T, U extends Cloneable> implements Printable, Cloneable {

  public final T first;
  public final U second;

  public Pair(T first, U second) {
    this.first = first;
    this.second = second;
  }

  public static <T, U extends Cloneable> Pair<T, U> create(T first, U second) {
    return new Pair<>(first, second);
  }

  public static <T, U extends Cloneable> T getFirst(Pair<T, U> pair) {
    return pair.first;
  }
  
  public static <T, U extends Cloneable> U getSecond(Pair<T, U> pair) {
    return pair.second;
  }

  @Override
  public boolean equals(Object obj) {
    if (!(obj instanceof Pair)) {
      return false;
    }
    Pair otherPair = (Pair) obj;
    return Objects.equals(this.first, otherPair.first) 
           && Objects.equals(this.second, otherPair.second);
  }

  @Override
  public int hashCode() {
    return Objects.hash(this.first, this.second);
  }

  @Override
  public final String toString() {
    return "(" + this.first.toString() + ", " + this.second.toString() + ")";
  }

  @Override
  public final String print() {
    return "";
  }

  @Override
  public Pair<T, U> clone() {
    return new Pair<>((T) first, (U) second.clone());
  }

}