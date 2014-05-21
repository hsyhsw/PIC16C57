
#include <stdio.h>
#include "vpi_user.h"


int hello_world(PLI_BYTE8 *d)
{

	vpi_printf("VPI: Hello, VPI!\n");
	return 0;
}


int vpi_test_read(PLI_BYTE8 *d) {
	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);
	s_vpi_value v;
	v.format = vpiIntVal;
	v.value.integer = 0x12;
	vpi_put_value(tfObject, &v, NULL, vpiNoDelay);

	return 0;
}

int vpi_input_str(PLI_BYTE8 *d) {

	vpiHandle systfref, argh, argsiter;
	s_vpi_value v;
	systfref = vpi_handle(vpiSysTfCall, NULL);
	argsiter = vpi_iterate(vpiArgument, systfref);
	argh = vpi_scan(argsiter);
	
	if (!argh) {
		vpi_printf("$VPI: missing parameter\n");
		return 0;
	}
	
	v.format = vpiIntVal;
	vpi_get_value(argh, &v);
	
	vpi_printf("VPI: %d\n", v.value.integer);
	// vpi_put_value(systfref, &v, NULL, vpiNoDelay);
	vpi_put_value(systfref, &v, NULL, vpiNoDelay);


	return 0;
}

void register_vpi_input_str() {
	s_vpi_systf_data systf;
	systf.type = vpiSysFunc;				//sysfunc 일시			//잠시 수정	sysFunc => inttask
	systf.sysfunctype = vpiIntFunc;			//func의 return type	//잠시 수정 IntFunc =>
	systf.tfname = "$vpi_input_str";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = vpi_input_str;
	vpi_register_systf(&systf);
}


void register_vpi_test_read() {
	s_vpi_systf_data systf;
	systf.type = vpiSysFunc;
	systf.sysfunctype = vpiIntFunc;
	systf.tfname = "$vpi_test_read";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = vpi_test_read;
	vpi_register_systf(&systf);
}


void register_hello_world_systfs() {
	s_vpi_systf_data systf_data;

	systf_data.type = vpiSysTask;
	systf_data.sysfunctype = vpiSysTask;
	systf_data.tfname = "$hello_world";
	systf_data.calltf = hello_world;
	systf_data.compiletf = 0; // func ptr not used should be initialized to NULL
	systf_data.sizetf = 0; // func ptr not used should be initialized to NULL
	systf_data.user_data = 0; // func ptr not used should be initialized to NULL

	vpi_register_systf(&systf_data);

}

void(*vlog_startup_routines[])() =
{
	register_hello_world_systfs,
	register_vpi_test_read,
	register_vpi_input_str,
	NULL
};

