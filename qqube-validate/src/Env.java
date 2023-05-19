public class Env {
  public final static int attempts = getAttempts();
  public final static boolean bad = attempts==0;
  private static int getAttempts(){
    try{
      return Integer.parseInt(System.getenv("attempts"));
    }catch(Throwable t){
      return 0;
    }
  }
}