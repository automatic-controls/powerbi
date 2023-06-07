public class _Variables {
  public _Item[] Items;
  public String get(String name){
    for (int i=0;i<Items.length;++i){
      if (name.equalsIgnoreCase(Items[i].name)){
        return Items[i].value;
      }
    }
    return null;
  }
}