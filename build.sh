#!/QOpenSys/usr/bin/sh
# ------------------------------------------------------------------------- #
# Program       : buildpgm.sh
# Author        : www.anandk.dev
# Date Written  : 27th October 2020
# Inspired from : https://github.com/barrettotte/RPGLE-Twilio/blob/master/build.sh
# ------------------------------------------------------------------------- #
# This program reads current folder from IFS and takes below steps.
# 1. It assumes these sources i.e. dspf, rpgle, sqlrpgle, clle.  
# 2. It copies .rpgle, .sqlrpgle, .clle and .dspf to respective _SRC. 
# 3. It compiles the DSPF first, then RPGLE, SQLRPGLE and finally CLLE. 
# After coping this program to IFS folder where your sources are, use below command
# to make this file executable.
# chmod +x buildpgm.sh
# Set the CUR_LIB to your library.
# Check if the SRCPFs are correct for you. 
# Set the application name which will be applied to all the memebers.
# ------------------------------------------------------------------------- #

# Set the IFS directory, if not given, set current
IFS_DIR="${1:-$(pwd)}"

# Set the current library where the programs will be compiled. 
CUR_LIB="RKAUSHIK1"

# Set source physical files 
DDS_SRC="QDDSSRCSSH"
RPGLE_SRC="QRPGLESRC"
CL_SRC="QCLSRC"

# Set application name
APPLICATION="Test Application"

# Execute the command by setting the library first
exec_cmd(){
    echo $1
    output=$(qsh -c "liblist -a $CUR_LIB ; system \"$1\"")
    if [ -n "$2" ]; then
    echo -e "$1\n\n$output" > "$IFS_DIR/$2.log"
    fi
}

# Copy PF to source PF and compile
crt_pf(){
  echo -e '\n... executing commands... '
  filename=$(basename "$1")
  member="${filename%.*}"
  exec_cmd "CHGATR OBJ('$1') ATR(*CCSID) VALUE(819)"
  exec_cmd "CPYFRMSTMF FROMSTMF('$1') TOMBR('/QSYS.lib/$CUR_LIB.lib/$DDS_SRC.file/$member.mbr') MBROPT(*REPLACE)"
  exec_cmd "CHGPFM FILE($CUR_LIB/$DDS_SRC) MBR($member) SRCTYPE(PF) TEXT('$APPLICATION')"
  exec_cmd "DLTOBJ ($CUR_LIB/$member) OBJTYPE(*FILE)"
  exec_cmd "CRTPF FILE($CUR_LIB/$member) SRCFILE($CUR_LIB/$DDS_SRC)" $member 
}

# Copy DSPF to source PF and compile
crt_dspf(){
  echo -e '\n... executing commands... '
  filename=$(basename "$1")
  member="${filename%.*}"
  exec_cmd "CHGATR OBJ('$1') ATR(*CCSID) VALUE(819)"
  exec_cmd "CPYFRMSTMF FROMSTMF('$1') TOMBR('/QSYS.lib/$CUR_LIB.lib/$DDS_SRC.file/$member.mbr') MBROPT(*REPLACE)"
  exec_cmd "CHGPFM FILE($CUR_LIB/$DDS_SRC) MBR($member) SRCTYPE(DSPF) TEXT('$APPLICATION')"
  exec_cmd "DLTOBJ ($CUR_LIB/$member) OBJTYPE(*FILE)"
  exec_cmd "CRTDSPF FILE($CUR_LIB/$member) SRCFILE($CUR_LIB/$DDS_SRC)" $member 
}

# Copy RPGLE to SRCPF and compile
crt_rpgle(){
  echo -e '\n... executing commands... '
  filename=$(basename "$1")
  member="${filename%.*}"
  exec_cmd "CHGATR OBJ('$1') ATR(*CCSID) VALUE(819)"
  exec_cmd "CPYFRMSTMF FROMSTMF('$1') TOMBR('/QSYS.lib/$CUR_LIB.lib/$RPGLE_SRC.file/$member.mbr') MBROPT(*REPLACE)"
  exec_cmd "CHGPFM FILE($CUR_LIB/$RPGLE_SRC) MBR($member) SRCTYPE(RPGLE) TEXT('$APPLICATION')"
  exec_cmd "DLTOBJ ($CUR_LIB/$member) OBJTYPE(*PGM)"
  exec_cmd "CRTBNDRPG PGM($CUR_LIB/$member) DFTACTGRP(*NO) DBGVIEW(*SOURCE)" $member   
}

# Copy SQLRPGLE to SRCPF and compile
crt_sqlrpgle(){
  echo -e '\n... executing commands... '
  filename=$(basename "$1")
  member="${filename%.*}"
  exec_cmd "CHGATR OBJ('$1') ATR(*CCSID) VALUE(819)"
  exec_cmd "CPYFRMSTMF FROMSTMF('$1') TOMBR('/QSYS.lib/$CUR_LIB.lib/$RPGLE_SRC.file/$member.mbr') MBROPT(*REPLACE)"
  exec_cmd "CHGPFM FILE($CUR_LIB/$RPGLE_SRC) MBR($member) SRCTYPE(SQLRPGLE) TEXT('$APPLICATION')"
  exec_cmd "DLTOBJ ($CUR_LIB/$member) OBJTYPE(*PGM)"
  exec_cmd "CRTSQLRPGI OBJ($CUR_LIB/$member) SRCFILE($CUR_LIB/$RPGLE_SRC) COMMIT(*NONE) DBGVIEW(*SOURCE)" $member   
}
                                                                   
# Copy CLLE to SRCPF and compile
crt_clle(){
echo -e '\n... executing commands... '
  filename=$(basename "$1")
  member="${filename%.*}"
  exec_cmd "CHGATR OBJ('$1') ATR(*CCSID) VALUE(819)"
  exec_cmd "CPYFRMSTMF FROMSTMF('$1') TOMBR('/QSYS.lib/$CUR_LIB.lib/$CL_SRC.file/$member.mbr') MBROPT(*REPLACE)"
  exec_cmd "CHGPFM FILE($CUR_LIB/$CL_SRC) MBR($member) SRCTYPE(CLLE) TEXT('$APPLICATION')"
  exec_cmd "DLTOBJ ($CUR_LIB/$member) OBJTYPE(*PGM)"
  exec_cmd "CRTBNDCL PGM($CUR_LIB/$member) SRCFILE($CUR_LIB/$CL_SRC) DFTACTGRP(*NO) ACTGRP(*CALLER) DBGVIEW(*SOURCE)" $member   
}

search_pf(){
    for FILE in "$IFS_DIR"/*
        do  
            if [[ "${FILE##*/}" == "$INPPARM" ]]; then
                echo -e " File $INPPARM found - Compiling "
                echo -e "\n=========== Building PF - $FILE ============="
                crt_pf $FILE 
                return
            elif [[ "$INPPARM" == "*all" ]]; then
                ext="${FILE##*.}"
                if [[ $ext == 'pf' ]]; then
                    echo -e "\n=========== Building PF - $FILE ============="
                    crt_pf $FILE 
                fi       
            fi    
        done
        if [[ "$INPPARM" != "*all" ]]; then
            echo -e " File $INPPARM not found - Aborting "  
        fi
}

search_dspf(){
    for FILE in "$IFS_DIR"/*
        do
            if [[ "${FILE##*/}" == "$INPPARM" ]]; then
                echo -e " Display File $INPPARM found - Compiling "
                echo -e "\n=========== Building DSPF - $FILE ============="
                crt_dspf $FILE 
                return
            elif [[ "$INPPARM" == "*all" ]]; then
                ext="${FILE##*.}"
                if [[ $ext == 'dspf' ]]; then
                    echo -e "\n=========== Building DSPF - $FILE ============="
                    crt_dspf $FILE 
                fi
            fi
        done
        if [[ "$INPPARM" != "*all" ]]; then
            echo -e " Display File $INPPARM not found - Aborting "  
        fi
}

search_rpgle(){
    for FILE in "$IFS_DIR"/*
        do
            if [[ "${FILE##*/}" == "$INPPARM" ]]; then
                echo -e " Program $INPPARM found - Compiling "
                echo -e "\n=========== Building RPGLE - $FILE ============="
                crt_rpgle $FILE 
                return
            elif [[ "$INPPARM" == "*all" ]]; then
                ext="${FILE##*.}"
                if [[ $ext == 'rpgle' ]]; then
                    echo -e "\n=========== Building RPGLE - $FILE ============="
                    crt_rpgle $FILE 
                fi
            fi  
        done
        if [[ "$INPPARM" != "*all" ]]; then
            echo -e " Program $INPPARM not found - Aborting "  
        fi
}

search_sqlrpgle(){
    for FILE in "$IFS_DIR"/*
        do
            if [[ "${FILE##*/}" == "$INPPARM" ]]; then
                echo -e " Program $INPPARM found - Compiling "
                echo -e "\n=========== Building SQLRPGLE - $FILE ============="
                crt_sqlrpgle $FILE 
                return
            elif [[ "$INPPARM" == "*all" ]]; then
                ext="${FILE##*.}"
                if [[ $ext == 'sqlrpgle' ]]; then
                    echo -e "\n=========== Building SQLRPGLE - $FILE ============="
                    crt_sqlrpgle $FILE 
                fi 
            fi
        done
        if [[ "$INPPARM" != "*all" ]]; then
            echo -e " Program $INPPARM not found - Aborting "  
        fi    
}

search_clle(){
    for FILE in "$IFS_DIR"/*
        do
            if [[ "${FILE##*/}" == "$INPPARM" ]]; then
                echo -e " Program $INPPARM found - Compiling "
                echo -e "\n=========== Building CLLE - $FILE ============="
                crt_clle $FILE 
                return
            elif [[ "$INPPARM" == "*all" ]]; then
                ext="${FILE##*.}"
                if [[ $ext == 'clle' ]]; then
                    echo -e "\n=========== Building CLLE - $FILE ============="
                    crt_clle $FILE
                fi
            fi
        done
        if [[ "$INPPARM" != "*all" ]]; then
            echo -e " Program $INPPARM not found - Aborting "  
        fi
}

echo -e "|=== Starting to build the files & programs for $APPLICATION ===|"
echo -e " Enter Your Program/File Name ( *all to compile all members in $CUR_LIB/QxxxSRC ): "
read INPPARM
          
ext="${INPPARM##*.}"
if [[ $ext == 'pf' ]]; then
    search_pf
elif [[ $ext == 'dspf' ]]; then
    search_dspf
elif [[ $ext == 'rpgle' ]]; then
    search_rpgle
elif [[ $ext == 'sqlrpgle' ]]; then
    search_sqlrpgle
elif [[ $ext == 'clle' ]]; then
    search_clle
elif [[ "$INPPARM" == "*all" ]]; then
    search_pf
    search_dspf
    search_rpgle
    search_sqlrpgle
    search_clle
fi

echo -e '|=================================================================================|'
echo -e '| Program build completed, please check if you encountered any errors.            |'
echo -e '| Check the log files created in the below folder.                                |'
echo -e "| $IFS_DIR                                                            |"
echo -e '|=================================================================================|'