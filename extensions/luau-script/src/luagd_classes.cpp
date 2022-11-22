#include "luagd_classes.h"

#include <lua.h>
#include <lualib.h>
#include <godot/gdnative_interface.h>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <godot_cpp/variant/string.hpp>

#include "luagd_stack.h"
#include "luau_script.h"

using namespace godot;

int luaGD_class_ctor(lua_State *L)
{
    StringName class_name = lua_tostring(L, lua_upvalueindex(1));

    GDNativeObjectPtr native_ptr = internal::gdn_interface->classdb_construct_object(&class_name);
    GDObjectInstanceID id = internal::gdn_interface->object_get_instance_id(native_ptr);

    Object *obj = ObjectDB::get_instance(id);
    LuaStackOp<Object *>::push(L, obj);

    // refcount is instantiated to 1.
    // we add a ref in the call above, so it's ok to decrement now to avoid object getting leaked
    RefCounted *rc = Object::cast_to<RefCounted>(obj);
    if (rc != nullptr)
        rc->unreference();

    return 1;
}

int luaGD_class_no_ctor(lua_State *L)
{
    const char *class_name = lua_tostring(L, lua_upvalueindex(1));
    luaL_error(L, "class %s is not instantiable", class_name);
}

#define LUAGD_CLASS_METAMETHOD                                          \
    int class_idx = lua_tointeger(L, lua_upvalueindex(1));              \
    ClassRegistry *class_reg = luaGD_lightudataup<ClassRegistry>(L, 2); \
                                                                        \
    const ClassInfo *current_class = &(*class_reg)[class_idx];

#define INHERIT_OR_BREAK                                          \
    if (current_class->parent_idx >= 0)                           \
        current_class = &(*class_reg)[current_class->parent_idx]; \
    else                                                          \
        break;

LuauScriptInstance *get_script_instance(lua_State *L)
{
    Object *self = LuaStackOp<Object *>::get(L, 1);
    Ref<LuauScript> script = self->get_script();

    if (script.is_valid() && script->_instance_has(self))
        return script->instance_get(self);

    return nullptr;
}

int luaGD_class_namecall(lua_State *L)
{
    LUAGD_CLASS_METAMETHOD

    if (const char *name = lua_namecallatom(L, nullptr))
    {
        if (LuauScriptInstance *inst = get_script_instance(L))
        {
            if (inst->has_method(name))
            {
                Vector<Variant> args;
                args.resize(lua_gettop(L) - 1);

                for (int i = 2; i <= lua_gettop(L); i++)
                    args.set(i - 2, LuaStackOp<Variant>::get(L, i));

                Variant ret;
                GDNativeCallError err;
                inst->call(name, args.ptr(), args.size(), &ret, &err);

                switch (err.error)
                {
                case GDNATIVE_CALL_OK:
                    LuaStackOp<Variant>::push(L, ret);
                    return 1;

                case GDNATIVE_CALL_ERROR_INVALID_ARGUMENT:
                    luaL_error(L, "invalid argument #%d to '%s' (%s expected, got %s)",
                               err.argument + 1,
                               name,
                               Variant::get_type_name((Variant::Type)err.expected).utf8().get_data(),
                               Variant::get_type_name(args[err.argument].get_type()).utf8().get_data());

                case GDNATIVE_CALL_ERROR_TOO_FEW_ARGUMENTS:
                    luaL_error(L, "missing argument #%d to '%s' (expected at least %d)",
                               args.size() + 2,
                               name,
                               err.argument);

                case GDNATIVE_CALL_ERROR_TOO_MANY_ARGUMENTS:
                    luaL_error(L, "too many arguments to '%s' (expected at most %d)",
                               name,
                               err.argument);

                default:
                    luaL_error(L, "unknown error occurred when calling '%s'", name);
                }
            }
            else
            {
                int nargs = lua_gettop(L);

                LuaStackOp<String>::push(L, name);
                bool is_valid = inst->table_get(L);

                if (is_valid)
                {
                    if (lua_isfunction(L, -1))
                    {
                        lua_insert(L, -nargs - 1);
                        lua_call(L, nargs, LUA_MULTRET);

                        return lua_gettop(L);
                    }
                    else
                    {
                        lua_pop(L, 1);
                    }
                }
            }
        }

        while (true)
        {
            if (current_class->methods.has(name))
                return current_class->methods[name](L);

            INHERIT_OR_BREAK
        }

        luaL_error(L, "%s is not a valid method of %s", name, current_class->class_name);
    }

    luaL_error(L, "no namecallatom");
}

int luaGD_class_global_index(lua_State *L)
{
    LUAGD_CLASS_METAMETHOD

    const char *key = luaL_checkstring(L, 2);

    while (true)
    {
        if (current_class->static_funcs.has(key))
        {
            lua_pushcfunction(L, current_class->static_funcs[key], key);
            return 1;
        }

        if (current_class->methods.has(key))
        {
            lua_pushcfunction(L, current_class->methods[key], key);
            return 1;
        }

        INHERIT_OR_BREAK
    }

    luaL_error(L, "%s is not a valid member of %s", key, current_class->class_name);
}

int luaGD_class_index(lua_State *L)
{
    LUAGD_CLASS_METAMETHOD

    const char *key = luaL_checkstring(L, 2);

    while (true)
    {
        if (current_class->properties.has(key))
        {
            lua_remove(L, 2);

            return current_class->methods[current_class->properties[key].getter_name](L);
        }

        INHERIT_OR_BREAK
    }

    luaL_error(L, "%s is not a valid member of %s", key, current_class->class_name);
}

int luaGD_class_newindex(lua_State *L)
{
    LUAGD_CLASS_METAMETHOD

    const char *key = luaL_checkstring(L, 2);

    while (true)
    {
        if (current_class->properties.has(key))
        {
            lua_remove(L, 2);

            return current_class->methods[current_class->properties[key].setter_name](L);
        }

        INHERIT_OR_BREAK
    }

    luaL_error(L, "%s is not a valid member of %s", key, current_class->class_name);
}
