/* aetherfetch — AetherOS system banner (compiled inside the image; no deps beyond libc). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/statvfs.h>
#include <time.h>
#include <unistd.h>

#define C1 "\033[38;5;75m"  /* cyan-blue */
#define C2 "\033[38;5;99m"  /* violet    */
#define CR "\033[0m"

static long uptime_days(void){ struct sysinfo s; sysinfo(&s); return s.uptime/86400; }
static long uptime_hrs(void){ struct sysinfo s; sysinfo(&s); return (s.uptime%86400)/3600; }
static void mem_gb(float *u, float *t){ struct sysinfo s; sysinfo(&s); *t=s.totalram*(float)s.mem_unit/(1024*1024*1024); *u=(s.totalram-s.freeram)*(float)s.mem_unit/(1024*1024*1024); }
static int pkgs(void){ FILE*f=popen("dpkg-query -f '.\\n' -W 2>/dev/null | wc -l","r"); int n=0; if(f){fscanf(f,"%d",&n); pclose(f);} return n; }
static void disk(char*out,size_t n){ struct statvfs v; if(statvfs("/", &v)) {snprintf(out,n,"?"); return;} double t=(double)v.f_blocks*v.f_frsize/(1024*1024*1024), u=(double)(v.f_blocks-v.f_bfree)*v.f_frsize/(1024*1024*1024); snprintf(out,n,"%.1f / %.0f GiB", u, t); }

int main(void){
    struct utsname u; uname(&u);
    float mu, mt; mem_gb(&mu,&mt);
    char dk[64]; disk(dk,sizeof dk);
    printf("\n");
    printf(C1"            @@@@@@@@@@            "CR"   "C2"AetherOS"CR" 1.0 (Nebula)\n");
    printf(C1"         @@@@@@@@@@@@@@@@         "CR"   ---------------\n");
    printf(C1"       @@@@@@@@@@@@@@@@@@@@       "CR"   Kernel : %s\n", u.release);
    printf(C2"      @@@@@@@@      @@@@@@@@      "CR"   Uptime : %ldd %ldh\n", uptime_days(), uptime_hrs());
    printf(C2"     @@@@@@@          @@@@@@@     "CR"   Memory : %.1f / %.1f GiB\n", mu, mt);
    printf(C2"     @@@@@@@   %s@@@@@@@@@@%s     "CR"   Disk   : %s\n", C1, C2, dk);
    printf(C2"     @@@@@@@          @@@@@@@     "CR"   Pkgs   : %d\n", pkgs());
    printf(C1"      @@@@@@@@      @@@@@@@@      "CR"   Shell  : %s\n", getenv("SHELL")?getenv("SHELL"):"/bin/bash");
    printf(C1"       @@@@@@@@@@@@@@@@@@@@       "CR"   DE     : Plasma (Wayland)\n");
    printf(C1"         @@@@@@@@@@@@@@@@         "CR"   GPU    : capability-driven\n");
    printf(C1"            @@@@@@@@@@            "CR"\n");
    printf("\n");
    return 0;
}
