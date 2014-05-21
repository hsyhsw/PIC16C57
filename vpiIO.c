#include <stdint.h> // uint8_t
#include <stddef.h> // NULL

#include <vpi_user.h>
#include <acc_user.h>

static int index; // stores global state

PLI_INT32 printPortOutput(PLI_BYTE8 *data) {
	// Get a handle to the system task/function call that invoked your PLI routine
	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);

	// Get an iterator for the arguments to your PLI routine
	vpiHandle argIterator = vpi_iterate(vpiArgument, tfObject);

	// Iterate through the arguments
	vpiHandle argument;
	argument = vpi_scan (argIterator);
	s_vpi_value val;
	val.format = vpiIntVal;
	vpi_get_value(argument, &val);
	

	vpi_printf("Port Output: %u\n", (uint16_t) val.value.integer);
	return 0;
}

PLI_INT32 feedValue1(PLI_BYTE8 *d) {
	// static int index;
	int arr[5] = { 50, 4, 3, 2, 1 };

	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);
	s_vpi_value v;
	v.format = vpiIntVal;
	v.value.integer = arr[index];
	vpi_put_value(tfObject, &v, NULL, vpiNoDelay);

	return 0;
}

PLI_INT32 feedValue2(PLI_BYTE8 *d) {
	// static int index;
	int arr[5] = { 10, 9, 8, 7, 6 };

	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);
	s_vpi_value v;
	v.format = vpiIntVal;
	v.value.integer = arr[index++];
	vpi_put_value(tfObject, &v, NULL, vpiNoDelay);

	return 0;
}

void register_feed1() {
	s_vpi_systf_data systf;
	systf.type = vpiSysFunc;
	systf.sysfunctype = vpiIntFunc;
	systf.tfname = "$feedValue1";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = feedValue1;
	vpi_register_systf(&systf);
}

void register_feed2() {
	s_vpi_systf_data systf;
	systf.type = vpiSysFunc;
	systf.sysfunctype = vpiIntFunc;
	systf.tfname = "$feedValue2";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = feedValue2;
	vpi_register_systf(&systf);
}

void registerFunction() {
	s_vpi_systf_data systf;
	systf.type = vpiSysTask;
	systf.sysfunctype = vpiSysTask;
	systf.tfname = "$printPortOutput";
	systf.compiletf = 0;
	systf.sizetf = 0;
	systf.user_data = 0;
	systf.calltf = printPortOutput;

	vpi_register_systf(&systf);
}

void (*vlog_startup_routines[])() = { registerFunction, register_feed1, register_feed2, NULL };
