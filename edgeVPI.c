#include <stdint.h> // uint8_t
#include <stddef.h> // NULL
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <vpi_user.h>
#include <acc_user.h>

typedef unsigned char    byte;
typedef unsigned short   word;
typedef unsigned int     uint;

#pragma pack(1) // 1바이트 단위로 저장
typedef struct BITMAPFILEHEADER { //FILE HEADER를 BITMAPFILEHEADER 이름의 구조체로 정의
    word bfType;
    uint bfSize;
    word bfReserved1;
    word bfReserved2;
    uint bfOffBits; //데이터 파일 시작 위치
} BITMAPFILEHEADER;

typedef struct BITMAPINFOHEADER { //Image Header를 BITMAPINFOHEADER 이름의 구조체로 정의
    uint biSize;
    int biWidth;
    int biHeight;
    word biPlanes;
    word biBitCount;
    uint biCompression;
    uint biSizeImage;
    int biXPelsPerMeter;
    int biYpelsperMeter;
    uint biClrUsed;
    uint biClrImortant;
} BITMAPINFOHEADER;

typedef struct RGBQUAD {
    byte rgbBlue;
    byte rgbGreen;
    byte rgbRed;
    byte rgbReserved;
} RGBQUAD;
#pragma pack()

static BITMAPFILEHEADER bf_header; // BITMAPFILEHEADER형 변수 bf_header선언
static BITMAPINFOHEADER bi_header; // BITMAPINFOHEADER형 변수 bi_header선언
static int Width;
static int Height;

static byte *bmp;
static byte *grey;
static size_t bmp_wbytes;  // 24 비트 이미지의 1 라인 바이트 수

static const char *bmp_name = "in.bmp";
static const char *grey_name = "out.bmp";

static int i = 1;
static int j = 1;
static int n;
static int m;

static byte temp_array[3][3];

/**
 * system task name: $init
 * agruments: N/A
 * return: N/A
 */
PLI_INT32 init(PLI_BYTE8 *data) {
    FILE *fbmp;
    byte  red, green, blue;
    int i, j;                

    // 원본 파일 열기
    fbmp = fopen(bmp_name, "rb");

    vpi_printf("image open successfully.\n");

    // 비트맵 파일 정보와 비트맵 정보 읽기
    fread(&bf_header, sizeof(bf_header), 1, fbmp);
    fread(&bi_header, sizeof(bi_header), 1, fbmp);

    // 비트맵 크기
    Width = bi_header.biWidth;
    Height = bi_header.biHeight;

    // 24비트 비트맵의 1 라인의 바이트 수가 4 의 배수가 되도록 수정
    bmp_wbytes = Width * 3;
    if (bmp_wbytes % 4 != 0)
    	bmp_wbytes += 4 - bmp_wbytes % 4;
    bmp = (byte *) malloc(sizeof(byte) * bmp_wbytes * Height);
	grey = (byte *) malloc(sizeof(byte) * bmp_wbytes * Height);

	vpi_printf("image info raedy.\n");
	vpi_printf("Width: %d\n", Width);
	vpi_printf("Height: %d\n", Height);
	vpi_printf("bmp_wbytes: %d\n", bmp_wbytes);

    // 비트맵 읽기
    fread(bmp, sizeof(byte), bmp_wbytes*Height, fbmp);
    fclose(fbmp);

    vpi_printf("rgb quad raedy.\n");

    // 그레이 변환
    for (i=0; i < Height; i++) {
        for (j=0; j < Width; j++) {
            // 그레이 변환
            blue  = bmp[bmp_wbytes*i + 3*j + 0];
            green = bmp[bmp_wbytes*i + 3*j + 1];
            red   = bmp[bmp_wbytes*i + 3*j + 2];
            grey[bmp_wbytes*i + 3*j] = ((red + green + blue) /3);
			grey[bmp_wbytes*i + 3*j+1] = ((red + green + blue) /3);
			grey[bmp_wbytes*i + 3*j+2] = ((red + green + blue) /3);
        }

    }

    //검정으로 초기화.
    for (i=0; i < Height; i++) {
        for (j=0; j < Width; j++) {
            bmp[bmp_wbytes*i + 3*j] = 0;
            bmp[bmp_wbytes*i + 3*j+1] = 0;
            bmp[bmp_wbytes*i + 3*j+2] = 0;
        }

    }

    // vpi_printf("\tAdjacent pix: ");
	for (n = 0; n < 3; n++) {
		for (m = 0; m < 3; m++) {
			temp_array[n][m] = grey[(i + n - 1) * bmp_wbytes + 3 * (j + m - 1)];
			//vpi_printf("%d ", temp_array[n][m]);
		}
	}
	// vpi_printf("\n");

    vpi_printf("Input image data ready.\n\n");

    return 0;
}

/**
 * system task name: $readNextAdjacentPixel
 * agruments: N/A
 * return: uint8 brightness value
 */
PLI_INT32 readNextAdjacentPixel(PLI_BYTE8 *data) {
	static int index;

	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);
	s_vpi_value v;
	v.format = vpiIntVal;
	v.value.integer = temp_array[index / 3][index % 3];
	vpi_put_value(tfObject, &v, NULL, vpiNoDelay);

	//vpi_printf("\tadj pix #%d, b: %d\n", index, temp_array[index / 3][index % 3]);

	++index;
	if (index == 9)
		index = 0;

	return 0;
}

static int16_t convolH;
static int16_t convolV;

/**
 * system task name: $storeConvolH
 * agruments: int16 horizontal convolution result
 * return: N/A
 */
PLI_INT32 storeConvolH(PLI_BYTE8 *data) {
	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);
	vpiHandle argIterator = vpi_iterate(vpiArgument, tfObject);

	vpiHandle argument;
	argument = vpi_scan (argIterator);
	s_vpi_value val;
	val.format = vpiIntVal;
	vpi_get_value(argument, &val);

	convolH = val.value.integer;
	vpi_printf("\tH: %d\n", convolH);

	return 0;
}

/**
 * system task name: $storeConvolV
 * agruments: int16 vertical convolution result
 * return: N/A
 */
PLI_INT32 storeConvolV(PLI_BYTE8 *data) {
	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);
	vpiHandle argIterator = vpi_iterate(vpiArgument, tfObject);

	vpiHandle argument;
	argument = vpi_scan (argIterator);
	s_vpi_value val;
	val.format = vpiIntVal;
	vpi_get_value(argument, &val);

	convolV = val.value.integer;
	vpi_printf("\tV: %d\n", convolV);

	return 0;
}

/**
 * system task name: $storePixel
 * agruments: N/A
 * return: N/A
 */
#define SOBEL_THRESHOLD (255)
PLI_INT32 storePixel(PLI_BYTE8 *data) {
	int32_t newBrightness32;
	newBrightness32 = convolV * convolV + convolH * convolH;
	newBrightness32 = sqrt(newBrightness32);

	// byte newBrightness8;
	if (newBrightness32 >= SOBEL_THRESHOLD)
		newBrightness32 = 0xFF;

	// vpi_printf("storing new pixel @(%d, %d)...\n", i, j);

	bmp[bmp_wbytes*i + 3*j] = newBrightness32;
	bmp[bmp_wbytes*i + 3*j+1] = newBrightness32;
	bmp[bmp_wbytes*i + 3*j+2] = newBrightness32;

	vpi_printf("stored new pixel @%d, %d\n", i, j);

	++j;
	if (j >= Width - 1) {
		j = 1;
		++i;
	}

	if (i != Height - 1) { // if not finished
	    // vpi_printf("\tAdjacent pix: ");
		for (n = 0; n < 3; n++) {
			for (m = 0; m < 3; m++) {
				temp_array[n][m] = grey[(i + n - 1) * bmp_wbytes + 3 * (j + m - 1)];
				//vpi_printf("%d ", temp_array[n][m]);
			}
		}
		// vpi_printf("\n");
	}

	return 0;
}

/**
 * system task name: $finished
 * agruments: N/A
 * return: int16 0x00 if not finished, 0xFF if finished
 */
PLI_INT32 finished(PLI_BYTE8 *data) {
	byte ret;

	if (i == Height - 1) {
		// 파일 저장
		FILE *fgrey;
		fgrey = fopen(grey_name, "wb");
		fwrite(&bf_header, sizeof(bf_header), 1, fgrey);            // BMPFILE헤더 저장
		fwrite(&bi_header, sizeof(bi_header), 1, fgrey);            // BMPINFO헤더 저장
		fwrite(bmp, sizeof(byte), bmp_wbytes * Height, fgrey);    // 비트맵 저장
		fclose(fgrey);

		vpi_printf("edge image saved.\n");

		ret = 0xFF;
	} else {
		ret = 0x00;
	}

	vpiHandle tfObject = vpi_handle(vpiSysTfCall, NULL);
	s_vpi_value v;
	v.format = vpiIntVal;
	v.value.integer = ret;
	vpi_put_value(tfObject, &v, NULL, vpiNoDelay);

	return 0;
}

///////////////////////////////////
/**
 * system task name: $init
 * agruments: N/A
 * return: N/A
 */
void reg_init() {
	s_vpi_systf_data systf;
	systf.type = vpiSysTask;
	systf.sysfunctype = vpiSysTask;
	systf.tfname = "$init";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = init;
	vpi_register_systf(&systf);
}

/**
 * system task name: $readNextAdjacentPixel
 * agruments: N/A
 * return: uint8 brightness value
 */
void reg_readNextAdjacentPixel() {
	s_vpi_systf_data systf;
	systf.type = vpiSysFunc;
	systf.sysfunctype = vpiIntFunc;
	systf.tfname = "$readNextAdjacentPixel";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = readNextAdjacentPixel;
	vpi_register_systf(&systf);
}

/**
 * system task name: $storeConvolH
 * agruments: int16 horizontal convolution result
 * return: N/A
 */
void reg_storeConvolH() {
	s_vpi_systf_data systf;
	systf.type = vpiSysTask;
	systf.sysfunctype = vpiSysTask;
	systf.tfname = "$storeConvolH";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = storeConvolH;
	vpi_register_systf(&systf);
}

/**
 * system task name: $storeConvolV
 * agruments: int16 vertical convolution result
 * return: N/A
 */
void reg_storeConvolV() {
	s_vpi_systf_data systf;
	systf.type = vpiSysTask;
	systf.sysfunctype = vpiSysTask;
	systf.tfname = "$storeConvolV";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = storeConvolV;
	vpi_register_systf(&systf);
}

/**
 * system task name: $storePixel
 * agruments: uint8 calculated pixel
 * return: N/A
 */
void reg_storePixel() {
	s_vpi_systf_data systf;
	systf.type = vpiSysTask;
	systf.sysfunctype = vpiSysTask;
	systf.tfname = "$storePixel";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = storePixel;
	vpi_register_systf(&systf);
}

/**
 * system task name: $finished
 * agruments: N/A
 * return: uint8 0x0 if not finished, 0xF if finished
 */
void reg_finished() {
	s_vpi_systf_data systf;
	systf.type = vpiSysFunc;
	systf.sysfunctype = vpiIntFunc;
	systf.tfname = "$finished";
	systf.compiletf = 0; // func ptr not used should be initialized to NULL
	systf.sizetf = 0; // func ptr not used should be initialized to NULL
	systf.user_data = 0; // func ptr not used should be initialized to NULL
	systf.calltf = finished;
	vpi_register_systf(&systf);
}
///////////////////////////////////

PLI_INT32 printPortOutput(PLI_BYTE8 *d) {
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
	

	vpi_printf("Port Output: 0x%4X\n", val.value.integer);
}

void reg_printPortOutput() {
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

void (*vlog_startup_routines[])() = {
	reg_init,
	reg_finished,
	reg_printPortOutput,
	reg_readNextAdjacentPixel,
	reg_storeConvolV,
	reg_storeConvolH,
	reg_storePixel,
	NULL
};
