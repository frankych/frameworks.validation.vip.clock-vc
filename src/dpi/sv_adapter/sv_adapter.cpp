#include "sv_adapter_common.h"
using namespace std;

void CdieAddVCCollateralPath() {
	string cdie_vc_collateral_path(CDIE_VC_COLLATERAL_PATH);
	add_python_module_path(cdie_vc_collateral_path);
}

  
void CdieAddAllPythonPaths() {
	CdieAddVCCollateralPath();
}

extern "C" void start_pydoh_agents() {
    set_pydoh_gcc_lib("lib/gcc_4.7.2");
    call_python_method("start_agent_mains", "Models.Socn.PydohSimMain");
    call_python_method("build_sim_run_control_agent", "Models.Socn.PydohSimMain");
}

extern "C" void start_cdie_cold_boot_sequence() {
	call_python_method("start_cdie_cold_boot_sequence", "CdieVC.CdieVcDirectMethods", NULL);
}

extern "C" void cdie_add_pydoh_paths() {
	printf("CDIE: Adding PyDoh Paths\n");
	CdieAddAllPythonPaths();
}

extern "C" void cdie_pydoh_drive_sb_signals(int pmsb_qreqn, int gpsb_qreqn, int idi_qreqn, int pmsb_iso_req_b, int gpsb_iso_req_b, int idi_iso_req_b, int coherent_traffic_req, int thermtripout, int prochot_indication){
	PyObject* pyargs = Py_BuildValue("(iiiiiiiii)", pmsb_qreqn, gpsb_qreqn, idi_qreqn, pmsb_iso_req_b, gpsb_iso_req_b, idi_iso_req_b, coherent_traffic_req, thermtripout, prochot_indication);
	call_python_method("cdie_drive_sb_signals", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_pydoh_drive_local_half_bridge_rst(int value){
	PyObject* pyargs = Py_BuildValue("(i)", value);
	call_python_method("cdie_drive_local_half_bridge_rst", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_send_power_info(){
	call_python_method("send_power_info", "CdieVC.CdieVcDirectMethods");
}

extern "C" void initialize_cdie_vc(){
	call_python_method("initialize_cdie_vc", "CdieVC.CdieVcDirectMethods");
}

extern "C" void cdie_set_target_state(char* state){
	PyObject* pyargs = Py_BuildValue("(s)", state);
	call_python_method("set_target_power_state", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_load_gpsb_cr_data(int portid, int address, unsigned long long data){
	PyObject* pyargs = Py_BuildValue("(iiK)", portid, address, data);
	call_python_method("cdie_load_gpsb_cr_data", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_load_pmsb_cr_data(int portid, int address, unsigned long long data){
	PyObject* pyargs = Py_BuildValue("(iiK)", portid, address, data);
	call_python_method("cdie_load_pmsb_cr_data", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_load_gpsb_mem_data(int address, unsigned long long data){
	PyObject* pyargs = Py_BuildValue("(iK)", address, data);
	call_python_method("cdie_load_gpsb_mem_data", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_load_pmsb_mem_data(int address, unsigned long long data){
	PyObject* pyargs = Py_BuildValue("(iK)", address, data);
	call_python_method("cdie_load_pmsb_mem_data", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_power_state_response_handler_set_min_state(int state){
	PyObject* pyargs = Py_BuildValue("(i)", state);
	call_python_method("cdie_power_state_response_handler_set_min_state", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_power_state_response_handler_set_max_state(int state){
	PyObject* pyargs = Py_BuildValue("(i)", state);
	call_python_method("cdie_power_state_response_handler_set_max_state", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_power_state_response_handler_set_ack_state(int ack){
	PyObject* pyargs = Py_BuildValue("(i)", ack);
	call_python_method("cdie_power_state_response_handler_set_ack_state", "CdieVC.CdieVcDirectMethods", pyargs);
}

extern "C" void cdie_send_svid_seq(int enable_alert, int command, int payload){
	PyObject* pyargs = Py_BuildValue("(iii)", enable_alert, command, payload);
	call_python_method("cdie_send_user_svid_seq", "CdieVC.CdieVcDirectMethods", pyargs);
}
