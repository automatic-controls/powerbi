public class Env {
  public final static String twp_api_secret = System.getenv("twp_api_secret");
  public final static String twp_site_id = System.getenv("twp_site_id");
  public final static String postgresql_url = System.getenv("postgresql_url");
  public final static String postgresql_user = System.getenv("postgresql_user");
  public final static String postgresql_pass = System.getenv("postgresql_pass");
  public final static int attempts = getAttempts();
  public final static boolean bad =
    twp_api_secret==null
    || twp_site_id==null
    || postgresql_url==null
    || postgresql_user==null
    || postgresql_pass==null
    || attempts==0;
  private static int getAttempts(){
    try{
      final String s = System.getenv("attempts");
      return s==null?0:Integer.parseInt(s);
    }catch(Throwable t){
      return 0;
    }
  }
}