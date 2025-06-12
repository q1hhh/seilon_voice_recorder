enum OpenLockTime {  
  Five,  
  Ten,
  Thirty,  
  Sixty  
}  
   
final Map<int, OpenLockTime> timeIntMap = {  
  5: OpenLockTime.Five,  
  10: OpenLockTime.Ten,  
  30: OpenLockTime.Thirty,  
  60: OpenLockTime.Sixty  
};  
    
final Map<OpenLockTime, String> timeDescriptionMap = {  
  OpenLockTime.Five: "5s",   
  OpenLockTime.Ten: "10s",  
  OpenLockTime.Thirty: "30s",   
  OpenLockTime.Sixty: "60s"   
};  
   
String getDescriptionFromTimeInt(int value) {   
  if (timeIntMap.containsKey(value)) {   
    OpenLockTime volume = timeIntMap[value]!;   
    return timeDescriptionMap[volume]!;  
  } else {   
    return "无效的时间级别";  
  }  
}  
 
List<int> timeFromMap = timeIntMap.keys.toList();
   
   