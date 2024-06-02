import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class BugCheckTask implements Runnable {
  public final String progName;
  public final String progPath;

  public BugCheckTask(String progName) {
    this.progName = progName;
    this.progPath = ConcurrentFuzzer.TEMP_DIR + progName;
  }

  @Override
  public void run() {
    List<Integer> exitCodes;
    try {
      exitCodes = compileProgram();
    } catch (Exception e) {
      System.out.println("UNEXPECTED ERROR when trying to compile " + progName + "(ignoring bug checking)");
      cleanUp();
      return;
    }

    assert(exitCodes.size() == ConcurrentFuzzer.COMPILERS.length);
    if (!exitCodes.stream().allMatch(item -> item == 0)) {
      File destination;
      if (exitCodes.stream().allMatch(item -> item == exitCodes.getFirst())) {
        System.out.println("BUG FOUND: all compilers failed to compile " + progName);
        destination = new File(ConcurrentFuzzer.COMPILER_ERROR_BUG_DIR + progName);
      } else {
        System.out.println("BUG FOUND: some compilers failed to compile " + progName);
        destination = new File(ConcurrentFuzzer.COMPILER_ERROR_MISMATCH_BUG_DIR + progName);
      }
      try {
        destination.createNewFile();
      } catch (IOException e) {}
      
      new File(progPath).renameTo(destination);
      cleanUp();
      return;
    }
    List<String> runResults;
    try {
      runResults = runProgram();
    } catch (Exception e) {
      System.out.println("UNEXPECTED ERROR when trying to run " + progName + "(ignoring bug checking)");
      System.out.println(e);
      cleanUp();
      return;
    }

    assert(runResults.size() == ConcurrentFuzzer.COMPILERS.length);
    if (!runResults.stream().allMatch(item -> item.equals(runResults.getFirst()))) {
      System.out.println("BUG FOUND: Miscompilation found when running " + progName);
      File destination = new File(ConcurrentFuzzer.COMPILER_MISCOMPILATION_BUG_DIR + progName);
      try {destination.createNewFile();} catch (IOException e) {}
      new File(progPath).renameTo(destination);
    }
    cleanUp();
  }
  private List<String> runProgram() throws Exception {
    List<String> results = new ArrayList<>();
    for (String compiler : ConcurrentFuzzer.COMPILERS) {
      ProcessBuilder pb = new ProcessBuilder("./runCompiledJar.sh", "../" + ConcurrentFuzzer.TEMP_DIR + jarName(progName, compiler));
      pb.directory(new File("./scripts"));

      Process p = pb.start();
      String errors = new String(p.getErrorStream().readAllBytes());
      String output = new String(p.getInputStream().readAllBytes());
      int exitCode = p.waitFor();
      if (exitCode == 124) {
        throw new RuntimeException("Compiling " + progName + " timed out");
      }

      results.add(output + errors);
    }
    return results;
  }

  private void cleanUp() {
    new File(progPath).delete();
    for (String compiler : ConcurrentFuzzer.COMPILERS) {
      String jarPath = ConcurrentFuzzer.TEMP_DIR + jarName(progName, compiler);
      new File(jarPath).delete();
    }
  }

  private String jarName(String progName, String compiler) {
    return progName.split(".kt")[0] + compiler + ".jar";
  }

  private List<Integer> compileProgram() throws Exception {
    List<Integer> exitCodes = new ArrayList<>();
    for (String compiler : ConcurrentFuzzer.COMPILERS) {
      ProcessBuilder pb = new ProcessBuilder("./compileProgram.sh", 
      "../" + ConcurrentFuzzer.COMPILERS_DIR + compiler, 
      "../" + progPath, 
      "../" + ConcurrentFuzzer.TEMP_DIR + jarName(progName, compiler));
      pb.directory(new File("./scripts"));
      Process p = pb.start();
      int exitCode = p.waitFor();
      if (exitCode == 124) {
        throw new RuntimeException("Compiling " + progName + " timed out");
      }
      exitCodes.add(exitCode);
    } 
    return exitCodes;
  }
}
