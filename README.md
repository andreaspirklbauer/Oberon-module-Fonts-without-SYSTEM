# Oberon-module-Fonts-without-SYSTEM
Module *Fonts* of the Project Oberon system which does not use the pseudo module SYSTEM

Note: In this repository, the term "Project Oberon 2013" refers to a re-implementation of the original "Project Oberon" on an FPGA development board around 2013, as published at www.projectoberon.com.

------------------------------------------------------
# Instructions for using the modified module Fonts in Project Oberon 2013 or Extended Oberon

**PREREQUISITES**: A current version of Project Oberon 2013 (http://www.projectoberon.com) or Extended Oberon (http://github.com/andreaspirklbauer/Oberon-extended). If you use Extended Oberon, the modified module *Fonts* of "Variant1" is already installed on your system.

------------------------------------------------------

Download all files from the desired variant of [**Sources**](Sources/) directory of this repository.

Convert the downloaded files to Oberon format (Oberon uses CR as line endings) using the command [**dos2oberon**](dos2oberon), also available in this repository (example shown for Mac or Linux):

     for x in *.Mod ; do ./dos2oberon $x $x ; done

Import the files to your Oberon system. If you use an emulator (e.g., **https://github.com/pdewacht/oberon-risc-emu**) to run the Oberon system, click on the *PCLink1.Run* link in the *System.Tool* viewer, copy the files to the emulator directory, and execute the following command on the command shell of your host system:

     cd oberon-risc-emu
     for x in *.Mod ; do ./pcreceive.sh $x ; sleep 1 ; done

Compile all downloaded modules found in the directory (and their clients, in particular the compiler!).

Restart your system (and compile any other client modules you have on your system).


