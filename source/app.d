module app;
import dlangui;
import std.math;

import std.file;
import std.stdio;
import std.format;
import std.datetime;
import std.algorithm;

import imageformats;
import dlib.image;
import dlib.image.image;
import dlib.image.io.png;
import dlib.image : savePNG;

mixin APP_ENTRY_POINT;


// Переменные для программы
int pen_color = 0x07e5f8;
//int background_color = 0xefeef2;
int background_color = 0x000000;

const int img_widht = 1280;
const int img_height = 720;


extern (C) int UIAppMain(string[] args) {
    // Создаем окно
    Window window = Platform.instance.createWindow("Attractor Example", null, WindowFlag.Resizable | WindowFlag.ExpandSize, img_widht, img_height);

    // Создаем CanvasWidget и настраиваем его
    CanvasWidget canvas = new CanvasWidget("canvas");
    canvas.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
    canvas.onDrawListener = (canvas, buf, rc) {
        onCanvasDraw(canvas, buf, rc);
    };

    // Устанавливаем CanvasWidget как основной для окна
    window.mainWidget = canvas;

    // Показываем окно
    window.show();

    // Цикл сообщений
    return Platform.instance.enterMessageLoop();
}

void onCanvasDraw(CanvasWidget canvas, DrawBuf buf, Rect rc) {
    // Заполняем фоновым цветом
    buf.fill(background_color);

    // Рисуем аттрактор
    drawAttractor(buf, rc.width, rc.height);

	/* Сохраняем изображение
    static int frameCount = 0;
    string filename = format("img/frame_%04d.png", frameCount);
    saveImage(buf, rc.width, rc.height, filename);
    frameCount++;
    */
}    


void drawAttractor(DrawBuf buf, double width, double height) {
	File file = File("coordinates.txt", "w");

	// Переменные
	int px, old_px;
    int py, old_py;

	// number of frames
	int number_of_frames = 10000;
	int max_scale_x = 1;
	int max_scale_y = 1;
	int max_scale = 1;
	
	Color4f pen_color_4f = Color4f(cast(float)((pen_color >> 16) & 0xFF) / 255.0f, cast(float)((pen_color >> 8) & 0xFF) / 255.0f, cast(float)((pen_color) & 0xFF) / 255.0f, 1);
	Color4f background_color_4f = Color4f(cast(float)((background_color >> 16) & 0xFF) / 255.0f, cast(float)((background_color >> 8) & 0xFF) / 255.0f, cast(float)((background_color) & 0xFF) / 255.0f, 1);


	// Параметры аттрактора
	double x = 0.1;
	double y = 0.0;
	double z = 0.0;

	double dt = 0.01;
	double sigma = 10;
	double rho = 28;
	double beta = 8 / 3;


	// width * height
	//SuperImage image = image(img_widht, img_height);
	//auto image = new Image!(PixelFormat.RGB8)(img_widht, img_height);
	SuperImage image = new Image!(IntegerPixelFormat.RGBA8)(img_widht, img_height);
	
	// Заполняем изображение фоновым цветом
	for(int iy = 0; iy < image.height; iy++)
		for(int ix = 0; ix < image.width; ix++) {
			// 0xEFEEF2
			image[ix, iy] = background_color_4f;
		}


	double abs_max_x = x;
	double abs_max_y = y;

	for (int i = 0; i <= number_of_frames; i++) {
		double dx = sigma * (y - x);
		double dy = x * (rho - z) - y;
		double dz = x * y - beta * z;

		x += dx * dt;
		y += dy * dt;
		z += dz * dt;

		if(abs(x) > abs_max_x)
			abs_max_x = abs(x);
		if(abs(y) > abs_max_y)
			abs_max_y = abs(y);
		
		max_scale_x = cast(int)floor((img_widht / 2 / abs_max_x));
		max_scale_y = cast(int)floor((img_height / 2 / abs_max_y));
		
		max_scale = min(max_scale_x, max_scale_y);
	}


	for (int i = 0; i <= number_of_frames; i++) {
		double dx = sigma * (y - x);
		double dy = x * (rho - z) - y;
		double dz = x * y - beta * z;

		x += dx * dt;
		y += dy * dt;
		z += dz * dt;

		old_px = px;
		old_py = py;
		px = cast(int)(round(x * max_scale + width / 2));
		// shift + 3 * / 10 * height
		py = cast(int)(round(-z * max_scale + height / 2 + height * 4 / 10 - height * 3 / 100));


		// Write coordinates to the file
		file.writeln(format("max_scale: %d", max_scale));
		file.writeln(format("%f %f %d %d", x, z, px, py));


		buf.drawPixel(px, py, pen_color);
		if(i >= 2) {
			//buf.drawLine(Point(old_px, old_py), Point(px, py), pen_color + i * 5);
			buf.drawLine(Point(old_px, old_py), Point(px, py), pen_color);
		}


		// 0x07e5f8
		image[px, py] = pen_color_4f;
		
		if(i >= 2) {
			//int color = pen_color + i * 5;
			int color = pen_color;
			drawLine(image, pen_color_4f, px, py, old_px, old_py);
		}

		// Сохраняем изображение
		//image.savePNG(image, format("img/frame_%04d.png", i));
		image.savePNG(format("img/frame_%04d.png", i));

	}

	file.close();
}

/*
void saveImage(DrawBuf buf, int width, int height, string filename) {
    SuperImage img = image(width, height);
    img.init(buf.pixels, buf.width, buf.height, ImageFormat.RGBA);

    if (img.save(filename, ImageFormat.PNG)) {
        writeln("Saved image: ", filename);
    } else {
        writeln("Failed to save image: ", filename);
    }
}
*/


// draw line with Bresenham method
void drawLine(SuperImage surface, Color4f color, int x1, int y1, int x2, int y2) {
	import std.algorithm;
	import std.math;

	float a = cast(float) x1;
	float b = cast(float) y1;
	float c = cast(float) x2;
	float d = cast(float) y2;

	float dx = (x2 - x1 >= 0 ? 1 : -1);
	float dy = (y2 - y1 >= 0 ? 1 : -1);
	
	float lengthX = abs(x2 - x1);
	float lengthY= abs(y2 - y1);
	float length = max(lengthX, lengthY);
	
	if (length == 0)
	{
		surface[cast(int) x1, cast(int) y1] = color;
	}
	
	if (lengthY <= lengthX)
	{
		float x = x1;
		float y = y1;
		
		length++;
		while (length--)
		{
			surface[cast(int) x, cast(int) y] = color;
			x += dx;
			y += (dy * lengthY) / lengthX;
		}
	}
	else
	{
		float x = x1;
		float y = y1;
		
		length++;
		while(length--)
		{
			surface[cast(int) x, cast(int) y] = color;
			x += (dx * lengthX) / lengthY;
			y += dy;
		}
	}
}
