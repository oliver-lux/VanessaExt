#ifndef __GHERKINPARSER_H__
#define __GHERKINPARSER_H__

#include "stdafx.h"
#include "AddInNative.h"

class GherkinParser:
    public AddInNative
{
private:
    static std::vector<std::u16string> names;
    GherkinParser();
};
#endif //__GHERKINPARSER_H__