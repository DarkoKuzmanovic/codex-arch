const Module = require("module");

const originalLoad = Module._load;

Module._load = function patchedLoad(request, parent, isMain) {
  const loaded = originalLoad.apply(this, [request, parent, isMain]);

  if (
    loaded &&
    typeof loaded === "object" &&
    typeof loaded.runMainAppStartup === "function" &&
    typeof request === "string" &&
    /main-[A-Za-z0-9_-]+\.js$/.test(request)
  ) {
    const originalRunMainAppStartup = loaded.runMainAppStartup;
    loaded.runMainAppStartup = async function wrappedRunMainAppStartup(...args) {
      try {
        return await originalRunMainAppStartup.apply(this, args);
      } catch (error) {
        console.error("runMainAppStartup error", error && error.stack ? error.stack : error);
        throw error;
      }
    };
  }

  return loaded;
};
