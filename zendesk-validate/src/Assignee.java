import java.util.*;
public class Assignee {
  public volatile String name;
  public volatile String email;
  public final ArrayList<BadTicket> problems = new ArrayList<BadTicket>();
  public Assignee(String name, String email){
    this.name = name;
    this.email = email;
  }
}