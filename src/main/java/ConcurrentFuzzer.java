import java.io.File;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.Random;


public class ConcurrentFuzzer {
  public static final int NUMBER_OF_PROGRAMS_PER_CONGIFG = 1;
  public static final int NUM_OF_THREADS = 3;
  public static final String TEMP_DIR = "output/tmp/fuzzing/";
  public static final String COMPILERS_DIR = "compilers/";
  public static final String[] COMPILERS = new String[] {
    "kotlin-compiler-1.9.24",
    "kotlin-compiler-2.0.0"
  };
  public static final String COMPILER_ERROR_BUG_DIR = "output/bugs/compiler-error/";
  public static final String COMPILER_ERROR_MISMATCH_BUG_DIR = "output/bugs/compiler-error-mismatch/";
  public static final String COMPILER_MISCOMPILATION_BUG_DIR = "output/bugs/compiler-micompilation/";

  public static void main(String[] args) {

    System.out.println("======== Starting concurrent fuzz ==========");
    String config = args[0];
    System.out.println("Using " + config + " for program generation");

    setupDirs();

    ExecutorService executor = Executors.newFixedThreadPool(NUM_OF_THREADS);
    Random random = new Random();

    int counter = 1;
    while (true) {
      String progName = "prog" + (random.nextLong()) + ".kt";
      GeneratorResult res = new GenerateTask(config, TEMP_DIR, progName).call();        

      executor.submit(new BugCheckTask(progName));
      counter++;
    }        
  }

  public static void setupDirs() {
    new File(COMPILER_ERROR_BUG_DIR).mkdirs();
    new File(COMPILER_ERROR_MISMATCH_BUG_DIR).mkdirs();
    new File(COMPILER_MISCOMPILATION_BUG_DIR).mkdirs();
    new File(TEMP_DIR).mkdirs();
  }
}