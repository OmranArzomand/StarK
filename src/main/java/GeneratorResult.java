
public class GeneratorResult {
  public final int numTimeouts;
  public final double wallGenerationTimeS;
  public final double cpuGenerationTimeS;
  public final int lineCount;
  public final int numCrashes;

  public GeneratorResult(int numTimeouts, double wallGenerationTimeS, double cpuGenerationTimeS, int lineCount, int numberOfCrashes) {
    this.numTimeouts = numTimeouts;
    this.wallGenerationTimeS = wallGenerationTimeS;
    this.cpuGenerationTimeS = cpuGenerationTimeS;
    this.lineCount = lineCount;
    this.numCrashes = numberOfCrashes;
  }
}
