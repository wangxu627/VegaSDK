#include "../include/App.h"
#include "../include/Android.h"
#include "../include/Log.h"
#include "../include/CApi.h"

// This cpp file contains some implementations of the App class available only for the Android platform.

#ifdef VEGA_ANDROID

#include <sstream>

using namespace std;
using namespace vega;

ANativeActivity* App::androidActivity = NULL;

ANativeWindow* App::androidWindow = NULL;

JNIEnv* App::scriptThreadJavaEnv = NULL;

/**
Returns the Android activity instance.
*/
ANativeActivity* App::GetAndroidActivity()
{
	return androidActivity;
}

/**
Sets the Android activity instance.
*/
void App::SetAndroidActivity(ANativeActivity* activity)
{
	androidActivity = activity;
}

/**
Returns the window instance related to the Android activity.
*/
ANativeWindow* App::GetAndroidWindow()
{
	return androidWindow;
}

/**
Sets the window instance related to the Android activity.
*/
void App::SetAndroidWindow(ANativeWindow* window)
{
	androidWindow = window;
}

/**
Returns the JNIEnv of the thread that is running the Lua scripts.
*/
JNIEnv* App::GetScriptThreadJavaEnv()
{
	return scriptThreadJavaEnv;
}

/**
Sets the JNIEnv of the thread that is running the Lua scripts.
*/
void App::SetScriptThreadJavaEnv(JNIEnv* env)
{
	scriptThreadJavaEnv = env;
}

extern "C"
{
	void onAndroidNativeWindowCreated(ANativeActivity* activity, ANativeWindow* window)
	{
		App::SetAndroidWindow(window);
		Log::Info("Native window created. Starting the script thread...");

		jobject javaActivityObject = activity->clazz;
		jmethodID executeScriptThreadMethodId = activity->env->GetMethodID(activity->env->GetObjectClass(javaActivityObject), "executeScriptThread", "()V");
		activity->env->CallVoidMethod(javaActivityObject, executeScriptThreadMethodId);
	}

	void ANativeActivity_onCreate(ANativeActivity* activity, void* savedState, size_t savedStateSize)
	{
		Log::Info("Native activity created.");
		App::SetAndroidActivity(activity);
		activity->callbacks->onNativeWindowCreated = onAndroidNativeWindowCreated;
	}

	JNIEXPORT void JNICALL Java_org_vega_VegaActivity_executeAppScript(JNIEnv *env, jobject obj, jstring s)
	{
		Log::Info("Executing entry point script...");
		App::SetScriptThreadJavaEnv(env);
		Log::Info("Creating App instance...");
		App app;
		string scriptName = env->GetStringUTFChars(s, 0);
		Log::Info("Preparing to execute script:");
		Log::Info(scriptName);
		app.Execute(scriptName);
	}
}

void App::InitAndroid()
{
	Log::Info("Initializing video...");
    const EGLint attribs[] = {
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_NONE
    };
    EGLint format;
    EGLint numConfigs;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    eglInitialize(display, 0, 0);
    eglChooseConfig(display, attribs, &config, 1, &numConfigs);
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);

    ANativeWindow_setBuffersGeometry(App::GetAndroidWindow(), 0, 0, format);

    surface = eglCreateWindowSurface(display, config, App::GetAndroidWindow(), NULL);
    context = eglCreateContext(display, config, NULL, NULL);

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE)
        Log::Error("Unable to eglMakeCurrent");

	eglSurface = surface;
	eglDisplay = display;
	sceneRender.Init();
	int w, h;
	GetScreenSize(&w, &h);
	sceneRender.SetScreenSize(w, h);
}

/**
Setup Lua to search the scripts (when the "require" function is used) in the assets folder.
It adds a new function into the package.searches function.
*/
void App::InitLuaSearches()
{
	Log::Info("Adding the assets search function into the package.searches function...");
	lua_getglobal(luaState, "package");
	lua_getfield(luaState, -1, "searchers");
	lua_len(luaState, -1);
	int searchesLength = lua_tonumber(luaState, -1);
	lua_pop(luaState, 1);
	lua_pushcfunction(luaState, SearchModuleInAssetsLuaFunction);
	lua_rawseti(luaState, -2, searchesLength + 1);
	lua_pop(luaState, 2);
}

/**
Process the input events.
*/
void App::ProcessInput()
{
	/*
	//old code from app glue:
	int eventId;
	int events;
	struct android_poll_source* source;
	while ((eventId = ALooper_pollAll(0, NULL, &events, (void**)&source)) >= 0)
	{
		if (source != NULL)
			source->process(App::GetAndroidActivity(), source);
		if (eventId == LOOPER_ID_USER)
		{
		}
		if (Context::GetAndroidApp()->destroyRequested != 0)
		{
			Log::Info("Destroy requested");
			CApi::GetInstance()->SetExecutingFieldToFalse();
			break;
		}
	}
	*/
	return 0;
}

void App::GetScreenSize(int *w, int *h)
{
	eglQuerySurface(eglDisplay, eglSurface, EGL_WIDTH, w);
	eglQuerySurface(eglDisplay, eglSurface, EGL_HEIGHT, h);
}

void App::OnRenderFinished()
{
	eglSwapBuffers(eglDisplay, eglSurface);
}

/**
The function to be added to the package.searches on Lua. It searches the module name (the input parameter)
in the assets folder. If not found, returns 0 results. Otherwise, returns 2 results: the load function and
the full asset name (directory and file name).
*/
int App::SearchModuleInAssetsLuaFunction(lua_State *luaState)
{
	string moduleName = lua_tostring(luaState, -1);
	stringstream moduleNameWithLuaExtension;
	moduleNameWithLuaExtension << moduleName << ".lua";
	stringstream moduleNameWithLCExtension;
	moduleNameWithLCExtension << moduleName << ".lc";
	// todo: is looking for the file on root dir and vega_lua dir; must be changedto look into the package.searchpath Lua field.
	list<string> dirs;
	dirs.push_back("");
	dirs.push_back("vega_lua");
	list<string> assetsNames;
	assetsNames.push_back(moduleName);
	assetsNames.push_back(moduleNameWithLuaExtension.str().c_str());
	assetsNames.push_back(moduleNameWithLCExtension.str().c_str());
	for (list<string>::iterator i = dirs.begin(); i != dirs.end(); ++i)
	{
		for (list<string>::iterator j = assetsNames.begin(); j != assetsNames.end(); ++j)
		{
			string fullAssetNameFound = SearchAssetOnDir(*i, *j);
			if (fullAssetNameFound.length() > 0)
			{
				lua_pushcfunction(luaState, LoadModuleFromAssetsLuaFunction);
				lua_pushstring(luaState, fullAssetNameFound.c_str());
				return 2;
			}
		}
	}
	return 0;
}

/**
Searches for the asset in the directory. Returns the full asset name (like "dir/asset") or empty
if not found.
*/
string App::SearchAssetOnDir(string dirName, string assetName)
{
	string foundAssetName;
	bool found = false;
	AAssetDir* dir = AAssetManager_openDir(App::GetAndroidActivity()->assetManager, dirName.c_str());
	const char* dirAsset = NULL;
	while ((dirAsset = AAssetDir_getNextFileName(dir)) != NULL)
	{
		string s = dirAsset;
		if (s == assetName)
		{
			found = true;
			if (dirName.length() > 0)
			{
				stringstream ss;
				ss << dirName << '/' << assetName;
				foundAssetName = ss.str().c_str();
			}
			else
				foundAssetName = assetName;
			break;
		}
	}
	AAssetDir_close(dir);
	if (found)
		return foundAssetName;
	else
		return "";
}

/**
Function used by the "require" function to load a module from the assets. It expects two input parameters
(the extra value = the asset name, and the module name, used for debug and messages) and returns 1 value
for the Lua (the value returned after run the loaded asset).
*/
int App::LoadModuleFromAssetsLuaFunction(lua_State *luaState)
{
	string extraValue = lua_tostring(luaState, -1);
	string moduleName = lua_tostring(luaState, -2);
	AAsset* asset = AAssetManager_open(App::GetAndroidActivity()->assetManager, extraValue.c_str(), AASSET_MODE_BUFFER);
	const void *data = AAsset_getBuffer(asset);
	size_t dataSize = AAsset_getLength(asset);
	if (luaL_loadbuffer(luaState, (const char*)data, dataSize, moduleName.c_str()))
		Log::Error(lua_tostring(luaState, -1));
	else if (lua_pcall(luaState, 0, 1, 0) != 0)
		Log::Error(lua_tostring(luaState, -1));
	AAsset_close(asset);
	return 1;
}

#endif // VEGA_ANDROID
