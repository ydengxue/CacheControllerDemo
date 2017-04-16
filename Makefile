#====================================================================================================
# Description:                 MakeFile
#                              
# Author:                      Dengxue Yan, Washington University in St. Louis
#                              
# Email:                       Dengxue.Yan@wustl.edu
#                             
# Version:                     1.00
#
# Rev History:  
#      <Author>        <Date>        <Hardware>     <Version>        
#     Dengxue Yan   2017-02-18 17:00       --           1.00             Create
#====================================================================================================
src = CacheController.v CacheController_tb.v
src1 = CacheController.v CacheController_tb1.v

vcs_flag = -full64 -PP +lint=all,noVCDE +v2k -timescale=1ns/10ps

all: simv simv1

simv: $(src)
	rm -rf csrc
	vcs $(vcs_flag) $^ -o $@

simv1: $(src1)
	rm -rf csrc
	vcs $(vcs_flag) $^ -o $@

run: simv simv1
	./simv +verbose=1 
	./simv1 +verbose=1 

.PHONY: clean
clean : 
	rm -rf csrc
	rm -f simv
	rm -f simv1
	rm -rf simv.daidir
	rm -rf simv1.daidir
	rm -f *.vcd*
	rm -f ucli.key
	rm -f *.log
	rm -rf DVEfiles
