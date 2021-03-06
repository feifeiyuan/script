#define INVALID_ARGV        -1  
#define FAILED_OPEN_FILE    -2  
#define MAX_AVALLABLE_FREQ  40  
#define BUFFER_SIZE         512  
  
#define CPU0_CUR_FREQ_PATH          "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"  
#define CPU4_CUR_FREQ_PATH          "/sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq"  

#define CPU0_AVAILABLE_FREQ_PATH    "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies"  
#define CPU4_AVAILABLE_FREQ_PATH    "/sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies"  
#define PROC_CPU_STAT               "/proc/stat"  
#define PCPU_PATH                   "/sdcard/stat_result.txt"  
  
typedef signed      int    si;  
typedef signed      char   s8;  
typedef unsigned    char   u8;  
typedef unsigned    int    ui;  
typedef unsigned long int  uli;  