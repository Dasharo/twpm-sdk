FROM ubuntu:23.04
RUN useradd -p locked -m builder -G dialout
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y install wget vim && mkdir -pm755 /etc/apt/keyrings && \
   wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
   wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/lunar/winehq-lunar.sources && \
   dpkg --add-architecture i386 && \
   apt-get update && \
   apt-get -y install --install-recommends winehq-staging p7zip-full xvfb && \
   apt-get -y install unzip make && apt-get clean
USER builder
# Initialize wine, install QuickWorks and yosys.
RUN wine wineboot && mkdir /tmp/install && cd /tmp/install && \
   wget https://github.com/QuickLogic-Corp/yosys-quickworks/raw/master/Releases/v1.0/ql-yosys-QuickWorks-v1.0.zip && \
   unzip ql-yosys-QuickWorks-v1.0.zip && \
   mv ql-yosys-v1.0 /home/builder && \
   cd QW2016.1.1_ReleaseBuild_0817 && \
   mkdir temp && cd temp && \
   7z x ../QW2016.1.1_ReleaseBuild_0817.exe && \
   xvfb-run wine QuickWorks.exe /qn && \
   cd / && rm -rf /tmp/install && ( \
      if [ ! -e ~/.wine/drive_c/QuickLogic/QuickWorks_2016.1.1_Release/spde/spde.exe ]; then \
         echo "SPDE not found" && exit 1; \
      fi \
   ) && wineserver -k && wine reg add "HKEY_LOCAL_MACHINE\\Software\\QuickLogic\\QuickWorks 2016.1.1 Release" \
      /t REG_SZ /v InstallPath /d "C:\\QuickLogic\\QuickWorks_2016.1.1_Release\\spde" /f
# Rename Clk_C16 and Clk_C21 to Sys_Clk0/1 for compatibility with SpDE which still
# uses older names for those signals.
RUN cd /home/builder/ql-yosys-v1.0/share/yosys/quicklogic/pp3 && \
   sed -i 's|Clk_C16|Sys_Clk0|g;s|Clk_C21|Sys_Clk1|g' 'qlal4s3b_sim.v'
# Variables used by TwPM build system
ENV TWPM_SPDE_DIR /home/builder/.wine/drive_c/QuickLogic/QuickWorks_2016.1.1_Release/spde
ENV TWPM_YOSYS_DIR /home/builder/ql-yosys-v1.0
RUN mkdir /home/builder/workspace
WORKDIR /home/builder/workspace
