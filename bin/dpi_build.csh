mkdir -p  $MODEL_ROOT/target/$DUT/dpi/tmp/sv_adapter/$SETUP_HOSTYPE
rm -rf $MODEL_ROOT/src/verif/dpi/cdie_libsv_adapter.so
cd $MODEL_ROOT/target/$DUT/dpi/tmp/sv_adapter/$SETUP_HOSTYPE; make -f $1 VC_ROOT=$2 TARGET=$MODEL_ROOT/src/verif/dpi/ ARCH=$SETUP_HOSTYPE
