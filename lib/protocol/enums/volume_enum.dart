enum Volume {  
  High,  
  Normal,
  Low,  
  Mute  
}  
   
final Map<int, Volume> volumeIntMap = {  
  3: Volume.High,  
  2: Volume.Normal,  
  1: Volume.Low,  
  0: Volume.Mute  
};  
    
final Map<Volume, String> volumeDescriptionMap = {  
  Volume.High: "High",  // 高音量
  Volume.Normal: "Normal", // 正常音
  Volume.Low: "Low",  // 低音量
  Volume.Mute: "Mute"  // 静音
};  
   
String getDescriptionFromInt(int value) {   
  if (volumeIntMap.containsKey(value)) {   
    Volume volume = volumeIntMap[value]!;   
    return volumeDescriptionMap[volume]! ?? "未知音量";  
  } else {   
    return "无效的音量级别";  
  }  
}  

int? getIntFromDescription(String volume) {  
    for (var entry in volumeIntMap.entries) {  
    if (entry.value == volume) {  
      return entry.key;  
    }  
  }  
  return null;  
}  

List<int> volumeFromMap = volumeIntMap.keys.toList();
 
   
     