public class Job {
  public volatile String id;
  public volatile boolean active;
  public volatile String name;
  public Job(String id, boolean active, String name){
    this.id = id;
    this.active = active;
    this.name = name;
  }
}