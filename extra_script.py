import os
Import("env")

project_dir = env.subst("$PROJECT_DIR")

# C-only flags (відповідає CFLAGS у Makefile)
env.Append(CFLAGS=[
    "-Os",
    "-std=gnu99"
])

# C++-only flags (відповідає CPPFLAGS у Makefile)
env.Append(CXXFLAGS=[
    "-Og",
    "-ggdb",
    "-Wall",
    "-Wextra",
    "-std=c++11",
    "-pedantic",
    "-fno-rtti",
    "-fno-exceptions",
    "-fno-unwind-tables"
])

# C++-only defines
env.Append(CPPDEFINES=[
    ("USART_BAUDRATE", "921600")
])

# Прапорці лінкера (відповідає LDFLAGS у Makefile)
env.Append(LINKFLAGS=[
    "-nostartfiles",
    "-march=armv7",
    "-Wl,--gc-sections",
    "-Wl,-Map," + env.subst("$BUILD_DIR") + "/linker.map"
])

# Бібліотеки для лінкування (відповідає -lopencm3_stm32f1 -lm у Makefile)
env.Append(LIBS=["opencm3_stm32f1", "m"])

# --- Додаткові директорії з вихідним кодом ---
# Замість library.json файлів — додаємо всі .c/.cpp з ccs/, exi/, libopeninv/src/
# безпосередньо до збірки. Так конфігурація не залежить від submodules.

extra_sources = []

for d in ["ccs", "exi", os.path.join("libopeninv", "src")]:
    full = os.path.join(project_dir, d)
    if os.path.isdir(full):
        for f in os.listdir(full):
            if f.endswith(".cpp") or f.endswith(".c"):
                extra_sources.append(os.path.join(full, f))

env.BuildSources(
    os.path.join("$BUILD_DIR", "extra_src"),
    project_dir,
    src_filter=" ".join(["-<*>"] + ["+<" + os.path.relpath(s, project_dir).replace("\\", "/") + ">" for s in extra_sources])
)
