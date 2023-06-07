import javax.crypto.*;
import javax.crypto.spec.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.*;
import java.text.*;
public class Utility {
  private final static Pattern formatter = Pattern.compile("\\$(\\d)");
  private final static Pattern flattener = Pattern.compile("[^\\p{ASCII}]");
  /**
   * Replaces occurrences of {@code $n} in the input {@code String} with the nth indexed argument.
   * For example, {@code format("Hello $0!", "Beautiful")=="Hello Beautiful!"}.
   */
  public static String format(final String s, final Object... args){
    final String[] args_ = new String[args.length];
    for (int i=0;i<args.length;++i){
      args_[i] = args[i]==null?"":Matcher.quoteReplacement(String.valueOf(args[i]));
    }
    return formatter.matcher(s).replaceAll(new java.util.function.Function<MatchResult,String>(){
      public String apply(MatchResult m){
        final int i = Integer.parseInt(m.group(1));
        return i<args.length?args_[i]:"";
      }
    });
  }
  public static String flatten(String s){
    return flattener.matcher(Normalizer.normalize(s, Normalizer.Form.NFD)).replaceAll("");
  }
  public static String HMACSHA256(String data, String key) throws Throwable {
    final Mac m = Mac.getInstance("HmacSHA256");
    m.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
    return base64UrlEncode(m.doFinal(data.getBytes(StandardCharsets.UTF_8)));
  }
  public static String base64UrlEncode(String message){
    return base64UrlEncode(message.getBytes(StandardCharsets.UTF_8));
  }
  public static String base64UrlEncode(byte[] arr){
    return Base64.getUrlEncoder().encodeToString(arr).replace("=","");
  }
}