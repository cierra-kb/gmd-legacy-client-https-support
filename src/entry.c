#include <curl/curl.h>
#include <dobby.h>

#include <android/log.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <jni.h>

#include "cainfo.c"

#ifdef ENABLE_LOGS
#define LOG(...) __android_log_print(ANDROID_LOG_DEBUG, "secnet-debug", __VA_ARGS__)
#else
#define LOG(...)
#endif

static CURL *detour_curl_easy_init() {
    CURL *curl = curl_easy_init();
    return curl;
}

static CURLcode detour_curl_easy_setopt(CURL *curl, CURLoption opt,
                                        long value) {
    switch (opt) {
    default:
        return curl_easy_setopt(curl, opt, value);
    }
}

static struct curl_slist *detour_curl_slist_append(struct curl_slist *list,
                                                   const char *element) {
    return curl_slist_append(list, element);
}

static void detour_curl_slist_free_all(struct curl_slist *list) {
    return curl_slist_free_all(list);
}

static CURLcode detour_curl_easy_perform(CURL *curl) {
    static const char HTTP_SCHEME[] = {'h', 't', 't', 'p', ':', '/', '/'};
    static const char HTTPS_SCHEME[] = {'h', 't', 't', 'p', 's', ':', '/', '/'};

    // Change the scheme to "https://" if the current one is "http://"
    // Do note that we are not updating the URL yet

    char* old_url = NULL;
    curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &old_url);

    char* new_url = NULL;

    if (strncmp(HTTP_SCHEME, old_url, sizeof(HTTP_SCHEME)) == 0) {
        new_url = malloc(strlen(old_url) + 2); // + 2 (one for an additional 's', one for the null terminator)
        memset(new_url, 0, strlen(old_url) + 2);
        memcpy(new_url, HTTPS_SCHEME, sizeof(HTTPS_SCHEME));
        memcpy(new_url + sizeof(HTTPS_SCHEME), old_url + sizeof(HTTP_SCHEME), strlen(old_url) - sizeof(HTTP_SCHEME));
        LOG("Changed \"http://\" to \"https://\": %s", new_url);
    } else {
        new_url = malloc(strlen(old_url) + 1); // + 1 (null terminator)
        memset(new_url, 0, strlen(old_url) + 1);
        memcpy(new_url, old_url, strlen(old_url));
        LOG("Retained URL: %s", new_url);
    }

    struct curl_blob cainfo_blob = {
        .data = CAInfoBlob,
        .len = CAInfoBlob_len,
        .flags = CURL_BLOB_NOCOPY
    };
    bool server_supports_https = false;

#ifdef CHECK_FOR_HTTPS_SUPPORT
    // Check if we can even communicate to the server with the new URL

    LOG("Checking if server accepts https connections..");

    CURL* test_client = curl_easy_init();
    curl_easy_setopt(test_client, CURLOPT_URL, new_url);
    curl_easy_setopt(test_client, CURLOPT_CONNECT_ONLY, 1);
    curl_easy_setopt(test_client, CURLOPT_SSL_VERIFYPEER, 1);
    curl_easy_setopt(test_client, CURLOPT_CAINFO_BLOB, &cainfo_blob);

    CURLcode test_result = curl_easy_perform(test_client);
    curl_easy_cleanup(test_client);

    server_supports_https = test_result == CURLE_OK;

    LOG("Resulting CURLcode: %i; server_supports_https = %s",
        test_result, (server_supports_https) ? "true" : "false");

#else
    LOG("Build is configured to not check for server support. Now assuming server_supports_https = true");
    server_supports_https = true;
#endif

#ifdef ALLOW_INSECURE_CONNECTIONS
#warning Current configuration allows for non-https connections
    if (server_supports_https) {
#else
    {
#endif
        curl_easy_setopt(curl, CURLOPT_URL, new_url);
        curl_easy_setopt(curl, CURLOPT_CAINFO_BLOB, &cainfo_blob);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1);
    }
    CURLcode result = curl_easy_perform(curl);
    free(new_url);

    return result;
}

static void detour_curl_easy_cleanup(CURL *curl) {
    return curl_easy_cleanup(curl);
}

static CURLcode detour_curl_easy_getinfo(CURL* curl, CURLINFO info, void* arg) {
    return curl_easy_getinfo(curl, info, arg);
}

JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved) {
    void *handle = NULL;

    if (!handle) {
        handle = dlopen("libgame.so", RTLD_NOW);
    }
    if (!handle) {
        handle = dlopen("libcocos2dcpp.so", RTLD_NOW);
    }
    if (!handle) {
        abort();
    }

    DobbyHook(dlsym(handle, "curl_easy_init"), &detour_curl_easy_init, NULL);
    DobbyHook(dlsym(handle, "curl_easy_setopt"), &detour_curl_easy_setopt,
              NULL);
    DobbyHook(dlsym(handle, "curl_slist_append"), &detour_curl_slist_append,
              NULL);
    DobbyHook(dlsym(handle, "curl_slist_free_all"), &detour_curl_slist_free_all,
              NULL);
    DobbyHook(dlsym(handle, "curl_easy_perform"), &detour_curl_easy_perform,
              NULL);
    DobbyHook(dlsym(handle, "curl_easy_cleanup"), &detour_curl_easy_cleanup,
              NULL);
    DobbyHook(dlsym(handle, "curl_easy_getinfo"), &detour_curl_easy_getinfo,
              NULL);

    return JNI_VERSION_1_4;
}
