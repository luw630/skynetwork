#===============================================================================
#      FILENAME: Makefile
#         USAGE: make            :generate executable
#                make clean      :remove objects, executable, prerequisits
#
#   DESCRIPTION: ---
#         NOTES: config.mk - define project configuration
#                build.mk  - auto-generate dependencies for c/c++ files
#                Remember to inlcude build.mk after all your targets!
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-02-28 by leoxiang
#===============================================================================#

INS_USER_DIR := ~/bin/lbf

LIB_FILES    := \
				lbf/basic_ssh.exp 	\
				lbf/lbf_array.sh 	\
				lbf/lbf_init.sh 	\
	            lbf/lbf_io.sh 		\
	            lbf/lbf_map.sh 		\
	            lbf/lbf_network.sh 	\
	            lbf/lbf_path.sh 	\
	            lbf/lbf_test.sh 	\
	            lbf/lbf_util.sh 	\
	 			temp/temp_server.sh \
	 			temp/temp_mysql.sh 	\

TEST_FILES   := $(wildcard test/*.sh)

install: ins_lib ins_bashrc
	@echo "Install LBF Success!"
	@echo "######### NOTICE: HOW TO USE ##########"
	@echo "# make install                        #"
	@echo "# source ~/.bashrc                    #"
	@echo "# lbf_help                            #"
	@echo "#######################################"

uninstall: uns_lib uns_bashrc
	@echo "Uninstall LBF Success!"

ins_lib:
	@mkdir -p $(INS_USER_DIR)
	@cp -rf $(LIB_FILES) ${INS_USER_DIR}
	@chmod a+x ${INS_USER_DIR}/*

ins_bashrc: uns_bashrc
	@touch $$HOME/.bashrc
	@echo "# inserted by auto-install script for LBF" >>~/.bashrc
	@echo "export PATH=\"\$$HOME/bin/lbf:\$$PATH\"" >>~/.bashrc
	@echo "source lbf_init.sh" >>~/.bashrc

uns_lib:
	@rm -rf ${INS_USER_DIR}/{lbf,lbf_temp}

uns_bashrc:
	@sed -i -re "/# inserted by auto-install script for LBF/,+2d" ~/.bashrc
	@sed -i -re "/# inserted by auto-install script for LBF ver 3/,+2d" ~/.bashrc
	@sed -i -re "/# inserted by auto-install script for LBF ver 4/,+2d" ~/.bashrc
	@sed -i -re "/# inserted by auto-install script for LBF ver 5/,+2d" ~/.bashrc
	@sed -i -re "/# inserted by auto-install script for LBF ver 6/,+2d" ~/.bashrc
	@sed -i -re "/# inserted by auto-install script for LBF ver 7/,+2d" ~/.bashrc

test:
	@chmod a+x lbf/*
	@for _test in $(TEST_FILES); do echo "start to run $$_test"; ./$$_test | grep "Failed" ; done || exit 0

tarball:
	tar zcvf ../lbf.tar.gz -C .. $(patsubst %,lbf/%,$(wildcard doc/* lib/* temp/* test/*) Makefile)

.PHONY: install uninstall tarball test 		\
		ins_lib ins_bashrc 	\
		uns_lib uns_bashrc 	\

# vim:ts=4:sw=4:ft=make:
