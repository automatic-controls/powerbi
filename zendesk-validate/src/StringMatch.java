public class StringMatch implements Comparable<StringMatch> {
  public volatile String s;
  public volatile int rating;
  public StringMatch(String s, int rating){
    this.s = s;
    this.rating = rating;
  }
  @Override public int compareTo(StringMatch m){
    return rating-m.rating;
  }
}