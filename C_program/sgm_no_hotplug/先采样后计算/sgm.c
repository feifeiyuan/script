#include <stdio.h>  
#include <string.h>  
#include <stdlib.h>  
#include <errno.h>  
#include <unistd.h>  
#include <sys/time.h>  
  
#include "sgm.h"  
  
static void debug_cpufreq_count(u8 cpu0_size,  ui *cpu0_available_freq,   
u8 cpu4_size, ui *cpu4_available_freq, ui total_count)  
{  
    u8 i = 0;  
    for(i=0;i<cpu0_size; i=i+2){  
        printf("%d\t%.2f%\n", cpu0_available_freq[i], cpu0_available_freq[i+1]*1.0/total_count*100);  
    }  
    printf("\n");  
      
    for(i=0;i<cpu4_size; i=i+2){  
        printf("%d\t%.2f%\n", cpu4_available_freq[i], cpu4_available_freq[i+1]*1.0/total_count*100);  
    }  
}  
  
  
static si get_argv(char *time_char)  
{  
    char *ch = time_char;  
    si ret = 0;  
      
    if( *ch == '0'){  
        fprintf(stderr, "interval should not be zero\n");  
        return INVALID_ARGV;  
    }  
  
    for(ch=time_char; *ch; ch++){  
        if( *ch == '-' || !(*ch >= '0' || *ch <= '9')){  
            fprintf(stderr, "please input the correct argv time(no negative)\n");  
            return INVALID_ARGV;  
        }  
        ret = ret*10+(*ch-'0');  
    }  
    return ret;  
}  
  
static s8 get_init_freq_count(const char *cpu_cur_path, u8 *size, ui *cpu_available_freq)  
{  
    FILE    *fp = NULL;  
    fp = fopen(cpu_cur_path, "r");  
    u8 i = 0;  
    if(fp==NULL){  
        fprintf(stderr, "failed opend file:", cpu_cur_path);  
        return INVALID_ARGV;  
    }  
    // even freq     
    // odd count  
    for(i=0; i<MAX_AVALLABLE_FREQ; i=i+2){  
        cpu_available_freq[i+1] = 0;  
        if(fscanf(fp,"%d", cpu_available_freq+i)!=1)  
            break;  
    }  
    *size = i;  
    fclose(fp);  
    return 0;  
}  
  
static void clear_envirment()  
{  
    remove(LITTLE_CORE);  
    remove(BIG_CORE);  
    remove(START_STAT);  
    remove(END_STAT);  
    remove(PCPU_PATH);  
}  
  
static s8 statistic_cpu_stat(const char *stat_path, ui count)  
{  
    FILE *fp = NULL;  
    FILE *fp_cpu = NULL;  
    char cpu_stat[BUFFER_SIZE];  
    char *result_stat;  
    u8 i = 0;  
      
    fp = fopen(stat_path, "r");  
    if(fp==NULL){  
        fprintf(stderr, "failed opend file:\n", stat_path);  
        return INVALID_ARGV;  
    }  
    if(count%2==0){  
        fp_cpu = fopen(START_STAT,"a");  
    }else{  
        fp_cpu = fopen(END_STAT,"a");  
    }  
      
    if(fp_cpu==NULL){  
        fprintf(stderr, "failed opend file:\n");  
        return INVALID_ARGV;  
    }  
    // aband sum pcpu   
    fgets(cpu_stat, BUFFER_SIZE, fp);  
      
    while(fgets(cpu_stat, BUFFER_SIZE, fp)&&i<8){  
        result_stat = cpu_stat+3;  
        fprintf(fp_cpu, "%s", result_stat);  
        i++;  
    }  
    fclose(fp);  
    fclose(fp_cpu);  
    return 0;  
}  
  
static s8 store_cpu_freq(ui cur_freq, char *file_path)  
{  
    FILE *fp = NULL;  
    fp = fopen(file_path, "a");  
    if(fp==NULL){  
        fprintf(stderr, "failed opend file:\n", file_path);  
        return FAILED_OPEN_FILE;  
    }  
    fprintf(fp, "%d\n", cur_freq);  
    fclose(fp);  
    return 0;  
}  
  
static ui get_store_cur_freq(const char *file_path, char *store_path)  
{  
    FILE    *fp = NULL;  
    ui cur_cpu_freq = 0;  
    fp = fopen(file_path, "r");  
    if(fp==NULL){  
        fprintf(stderr, "failed opend file:\n", file_path);  
        return INVALID_ARGV;  
    }  
    fscanf(fp, "%d", &cur_cpu_freq);  
    fclose(fp);  
    store_cpu_freq(cur_cpu_freq, store_path);  
    return 0;  
}  
  
  
static s8 data_simpling(si accummulate_time, si interval, ui total_count)  
{     
    struct timeval start, end;  
    float timeuse = 0.0;  
    uli   count = 0;  
    u8 i = 0;  
    gettimeofday(&start, NULL);  
    while(count<total_count){  
		if(count%2==1){
			get_store_cur_freq(CPU0_CUR_FREQ_PATH, LITTLE_CORE);  
			get_store_cur_freq(CPU4_CUR_FREQ_PATH, BIG_CORE); 
		}
        statistic_cpu_stat(PROC_CPU_STAT, count);  
        usleep(interval*1000);  
        count++;  
    }  
    gettimeofday(&end, NULL);  
    timeuse = (10000000 * ( end.tv_sec - start.tv_sec ) + end.tv_usec - start.tv_usec)/1000.0;  
    printf("time_use is %.2f\n", timeuse);  
      
}  
  
static s8 store_pcpu(u8 cpu_id,  float pcpu)  
{  
    FILE *fp = NULL;  
    fp = fopen(PCPU_PATH, "a");  
    if(fp==NULL){  
        fprintf(stderr, "failed opend file:\n", PCPU_PATH);  
        return FAILED_OPEN_FILE;  
    }  
    fprintf(fp, "%f\n",  pcpu);  
    fclose(fp);  
    return 0;  
}  
  
static si compute_cpu_loading_freq(char *start_file, char *end_file, float *pcpu_set)  
{  
    FILE *fp_start, *fp_end;  
    ui start_buffer[BUFFER_SIZE], end_buffer[BUFFER_SIZE];  
    memset(start_buffer, 0, BUFFER_SIZE);  
    memset(end_buffer, 0, BUFFER_SIZE);  
    u8 i = 0, cpu_id, j;  
    const u8 cpu_consist = 11;  
    uli  total_time = 0;  
    ui   idle_time = 0, set = 0;  
    float pcpu = 0.0;  
      
    fp_start = fopen(start_file, "r");  
    if(fp_start==NULL){  
        fprintf(stderr, "failed opend file", start_file);  
        return FAILED_OPEN_FILE;  
    }  
    fp_end = fopen(end_file, "r");  
    if(fp_end==NULL){  
        fprintf(stderr, "failed opend file", end_file);  
        return FAILED_OPEN_FILE;  
    }  
      
    while(fscanf(fp_start, "%d", start_buffer+i)==1 &&  
    fscanf(fp_end, "%d", end_buffer+i)==1){  
        if(i==0){  
            cpu_id = start_buffer[i];  
        }  
        ui minus = end_buffer[i]-start_buffer[i];  
        total_time+=minus;  
        if(i==4){  
            idle_time = minus;  
            //printf("%d\t%d\t%d\t%d\n", end_buffer[i], start_buffer[i], idle_time, total_time);  
        }  
        i++;  
        if(i==cpu_consist){  
            set++;  
            pcpu = ((total_time-idle_time)*1.0/total_time);  
            store_pcpu(cpu_id, pcpu);  
            pcpu_set[cpu_id]+=pcpu;  
            i=0;  
            total_time = 0;  
            memset(start_buffer, 0, BUFFER_SIZE);  
        }  
    }  
    set/=8;  
      
    fclose(fp_start);  
    fclose(fp_end);  
    return set;  
}  
  
static s8 calculate_freq_percent(const u8 cpu0_size,  ui *cpu0_available_freq,   
ui total_count, const u8 cpu4_size,  ui *cpu4_available_freq, si set_group)  
{  
    u8 i = 0, k;  
    ui j = 0;  
    FILE *fp_cpu0 = NULL;  
    FILE *fp_cpu4 = NULL;  
    FILE *fp_stat = NULL;  
    ui cpu0_cur_cpu, cpu4_cur_cpu, count;
	float total = 0;
    float pcpu[BUFFER_SIZE];  
    float pcpu_per[MAX_AVALLABLE_FREQ][BUFFER_SIZE*10];  
    ui   pcpu_per_count[MAX_AVALLABLE_FREQ][BUFFER_SIZE*10];  
	ui   cpu0_freq_online[MAX_AVALLABLE_FREQ],cpu0_freq_offline[MAX_AVALLABLE_FREQ];
	ui   cpu4_freq_online[MAX_AVALLABLE_FREQ],cpu4_freq_offline[MAX_AVALLABLE_FREQ];
	
    fp_cpu0 = fopen(LITTLE_CORE, "r");  
    if(fp_cpu0==NULL){  
        fprintf(stderr, "", LITTLE_CORE);  
        return FAILED_OPEN_FILE;  
    }  
    fp_cpu4 =fopen(BIG_CORE, "r");  
    if(fp_cpu4==NULL){  
        fprintf(stderr, "", BIG_CORE);  
        return FAILED_OPEN_FILE;  
    }  
    fp_stat = fopen(PCPU_PATH, "r");  
    if(fp_stat==NULL){  
        fprintf(stderr, "", PCPU_PATH);  
        return FAILED_OPEN_FILE;  
    }

	
    while(fscanf(fp_cpu0,"%d", &cpu0_cur_cpu)==1&&fscanf(fp_cpu4,"%d", &cpu4_cur_cpu)==1){
		i=0;  
        while(fscanf(fp_stat, "%f", pcpu+i)==1){
			for(j=0;j<cpu0_size;j=j+2){
				if(cpu0_cur_cpu==cpu0_available_freq[j]){
					cpu0_available_freq[j+1]++;
					if(pcpu[i]!=0){
						cpu0_freq_online[j] = cpu0_available_freq[j];
						cpu0_freq_online[j+1]++;
					}else{
						cpu0_freq_offline[j] = cpu0_available_freq[j];
						cpu0_freq_offline[j+1]++;
					}
				}
			}
			pcpu_per[i][cpu0_cur_cpu/1000]+=pcpu[i];  
			pcpu_per_count[i][cpu0_cur_cpu/1000]++;  
			//printf("%d\t%d\t%f\t\t%d\n", i, cpu0_cur_cpu, pcpu[i], pcpu_per_count[i][cpu0_cur_cpu/1000]);  
			i++;  
			if(i>3){
				break;  
			}  
        }  
        
		while(fscanf(fp_stat, "%f", pcpu+i)==1){
			for(j=0;j<cpu4_size;j=j+2){
				if(cpu4_cur_cpu==cpu4_available_freq[j]){
					cpu4_available_freq[j+1]++;
					if(pcpu[i]!=0){
						cpu4_freq_online[j] = cpu4_available_freq[j];
						cpu4_freq_online[j+1]++;
					}else{
						cpu4_freq_offline[j] = cpu4_available_freq[j];
						cpu4_freq_offline[j+1]++;
					}
				}
			}
			
			pcpu_per[i][cpu4_cur_cpu/1000]+=pcpu[i];  
            pcpu_per_count[i][cpu4_cur_cpu/1000]++;  
            //printf("%d\t%d\t%f\t\t%d\n", i, cpu4_cur_cpu, pcpu[i],pcpu_per_count[i][cpu4_cur_cpu/1000]);  
            i++;  
            if(i>7){  
                break;  
            }  
        }    
    }  
    fclose(fp_cpu0);  
    fclose(fp_stat);  
  
    for(j=0;j<cpu0_size;j=j+2){  
        if(j==0)  
            printf("   \t");  
        printf("%d\t\t", cpu0_available_freq[j]);  
        if(j==cpu0_size-2)  
            printf("\n");  
    }
	
	for(j=0;j<cpu0_size;j=j+2){  
        if(j==0)  
			printf("\t");  
		printf("%s\t%s\t", "online", "offline");  
        if(j==cpu0_size-2)  
            printf("\n");
	}
	for(j=0;j<cpu0_size;j=j+2){
		if(j==0)
			printf("\t");
		printf("%.2f%\t%.2f%\t",  cpu0_freq_online[j+1]*1.0/(set_group*4)*100, cpu0_freq_offline[j+1]*1.0/(set_group*4)*100);
	}
	printf("\n");
	

    for(i=0;i<4;i++){  
        printf("%d\t", i);  
        for(j=0;j<cpu0_size;j=j+2){  
			//printf("%.2f\t", pcpu_per[i][cpu0_available_freq[j]/1000]*1.0);
            if(pcpu_per_count[i][cpu0_available_freq[j]/1000]!=0){  
                printf("%.2f%\t\t", pcpu_per[i][cpu0_available_freq[j]/1000]/(pcpu_per_count[i][cpu0_available_freq[j]/1000])*100);  
            }else{  
                printf("0.00%\t\t");  
            }     
        }  
        printf("\n");  
    }  



    printf("\n");  
    for(j=0;j<cpu4_size;j=j+2){  
        if(j==0)  
            printf("   \t");  
        printf("%d\t\t", cpu4_available_freq[j]);  
        if(j==cpu4_size-2)  
            printf("\n");  
    }  
	
	for(j=0;j<cpu4_size;j=j+2){  
        if(j==0)  
			printf("\t");  
		printf("%s\t%s\t", "online", "offline");  
        if(j==cpu4_size-2)  
            printf("\n");
	}
	for(j=0;j<cpu4_size;j=j+2){
		if(j==0)
			printf("\t");
		printf("%.2f%\t%.2f%\t",  cpu4_freq_online[j+1]*1.0/(set_group*4)*100, cpu4_freq_offline[j+1]*1.0/(set_group*4)*100);
	}
	printf("\n");
	
    for(i=4;i<8;i++){  
        printf("%d\t", i);  
        for(j=0;j<cpu4_size;j=j+2){  
            if(pcpu_per_count[i][cpu4_available_freq[j]/1000]!=0){  
                printf("%.2f%\t\t", pcpu_per[i][cpu4_available_freq[j]/1000]/(pcpu_per_count[i][cpu4_available_freq[j]/1000])*100);  
            }else{  
                printf("0.00%\t\t");  
            }     
        }  
        printf("\n");  
    }  


    return 0;  
}  
  
int main(int argc, char *argv[])  
{  
    si   interval , accummulate_time = 0, set_group;  
    ui   cpu0_freq , cpu4_freq = 0;  
    ui   total_count = 0;  
    u8   cpu0_size, cpu4_size, i , j ;  
    ui   cpu0_available_freq[MAX_AVALLABLE_FREQ], cpu4_available_freq[MAX_AVALLABLE_FREQ];  
    float pcpu_set[BUFFER_SIZE];  
  
    // input argc less than 1  
    if( argc < 1 ){  
        fprintf(stderr, "you must input two argv");  
        fprintf(stderr, "first: cal cpu loading tool \n");  
        fprintf(stderr, "secn: interval time(default:100ms) \n");  
        fprintf(stderr, "expl: ./data/cpu_loading 100\n");  
        return INVALID_ARGV;  
    }  
      
    // input argc 1  
    if(argc==1){  
        interval = 100;  
        accummulate_time = 60;  
          
    // input argc 2  
    }else if(argc==2){  
        interval = get_argv(argv[1]);  
        if(interval<0){  
            return INVALID_ARGV;  
        }  
        accummulate_time = 60;  
    // input argc 3  
    }else{  
        interval = get_argv(argv[1]);  
        if(interval<0){  
            return INVALID_ARGV;  
        }  
        accummulate_time = get_argv(argv[2]);  
        if(accummulate_time<0){  
            return INVALID_ARGV;  
        }  
    }  
      
    printf("interval is %d\n", interval);  
    printf("accummulate_time is %d\n", accummulate_time);  
  
    get_init_freq_count(CPU0_AVAILABLE_FREQ_PATH, &cpu0_size, cpu0_available_freq);  
    get_init_freq_count(CPU4_AVAILABLE_FREQ_PATH, &cpu4_size, cpu4_available_freq);  
      
    // debug  
    //debug_cpufreq_count(cpu0_size, cpu0_available_freq ,cpu4_size, cpu4_available_freq);  
    total_count = (accummulate_time*1000)/interval;  
    clear_envirment();  
    // data cimpling  
    data_simpling(accummulate_time, interval, total_count);  
      
    set_group = compute_cpu_loading_freq(START_STAT, END_STAT, pcpu_set); 
	printf("set_group is %d\n", set_group);
	
    calculate_freq_percent(cpu0_size, cpu0_available_freq, total_count, cpu4_size,cpu4_available_freq, set_group);  
  
    return 0;  
}  