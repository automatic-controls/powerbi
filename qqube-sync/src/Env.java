public class Env {
  public final static String postgresql_url = System.getenv("postgresql_url");
  public final static String postgresql_port = System.getenv("postgresql_port");
  public final static String postgresql_database = System.getenv("postgresql_database");
  public final static String postgresql_user = System.getenv("postgresql_user");
  public final static String postgresql_pass = System.getenv("postgresql_pass");
  public final static int attempts = getAttempts();
  public final static boolean bad =
       postgresql_url==null
    || postgresql_port==null
    || postgresql_database==null
    || postgresql_user==null
    || postgresql_pass==null
    || attempts==0;
  private static int getAttempts(){
    try{
      return Integer.parseInt(System.getenv("attempts"));
    }catch(Throwable t){
      return 0;
    }
  }
}