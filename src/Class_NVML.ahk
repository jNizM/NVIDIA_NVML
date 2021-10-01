; ===========================================================================================================================================================================

/*
	AutoHotkey wrapper for NVIDIA NVML API

	Author ....: jNizM
	Released ..: 2020-09-29
	Modified ..: 2020-09-01
	License ...: MIT
	GitHub ....: https://github.com/jNizM/NVIDIA_NVML
	Forum .....: https://www.autohotkey.com/boards/viewtopic.php?t=95175
*/

; SCRIPT DIRECTIVES =========================================================================================================================================================

#Requires AutoHotkey v2.0-


; ===== NVML CORE FUNCTIONS ================================================================================================================================================

class NVML
{
	static _Init := NVML.__Initialize()


	static __Initialize()
	{
		if !(this.hModule := DllCall("LoadLibrary", "Str", "nvml.dll", "Ptr"))
		{
			MsgBox("NVML could not be startet!`n`nThe program will exit!", A_ThisFunc)
			ExitApp
		}
		if (NvStatus := DllCall("nvml\nvmlInit_v2", "CDecl") != 0)
		{
			MsgBox("NVML initialization failed: [ " NvStatus " ]`n`nThe program will exit!", A_ThisFunc)
			ExitApp
		}
	}



	static __Delete()
	{
		DllCall("nvml\nvmlShutdown", "CDecl")
		if (this.hModule)
			DllCall("FreeLibrary", "Ptr", this.hModule)
	}



	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: NVML.ErrorString
	; //
	; // Helper method for converting NVML error codes into readable strings.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static ErrorString(ErrorCode)
	{
		Result := DllCall("nvml\nvmlErrorString", "Int", ErrorCode, "Ptr")
		return StrGet(Result, "CP0")
	}

}



; ===== NVML DEVICE FUNCTIONS =================================================================================================================================================

class DEVICE extends NVML
{

	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: DEVICE.GetBrand
	; //
	; // Retrieves the brand of this device.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetBrand(hDevice)
	{
		static NVML_BRAND_TYPE := Map(0, "UNKNOWN", 1, "QUADRO", 2, "TESLA", 3, "NVS", 4, "GRID", 5, "GEFORCE", 6, "TITAN"
		                            , 7, "NVIDIA_VAPPS", 8, "NVIDIA_VPC", 9, "NVIDIA_VCS", 10, "NVIDIA_VWS", 11, "NVIDIA_VGAMING"
		                            , 12, "QUADRO_RTX", 13, "NVIDIA_RTX", 14, "NVIDIA", 15, "GEFORCE_RTX", 16, "TITAN_RTX")

		if !(NvStatus := DllCall("nvml\nvmlDeviceGetBrand", "Ptr", hDevice, "Int*", &BrandType := 0, "CDecl"))
		{
			return NVML_BRAND_TYPE[BrandType]
		}

		return this.ErrorString(NvStatus)
	}



	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: DEVICE.GetCount
	; //
	; // Retrieves the number of compute devices in the system. A compute device is a single GPU.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetCount()
	{
		if !(NvStatus := DllCall("nvml\nvmlDeviceGetCount_v2", "UInt*", &DeviceCount := 0, "CDecl"))
		{
			return DeviceCount
		}

		return this.ErrorString(NvStatus)
	}



	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: DEVICE.GetFanSpeed
	; //
	; // Retrieves the intended operating speed of the device's fan.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetFanSpeed(hDevice)
	{
		if !(NvStatus := DllCall("nvml\nvmlDeviceGetFanSpeed", "Ptr", hDevice, "UInt*", &FanSpeed := 0, "CDecl"))
		{
			return FanSpeed
		}

		return this.ErrorString(NvStatus)
	}



	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: DEVICE.GetHandleByIndex
	; //
	; // Retrieves the NVML index of this device.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetHandleByIndex(Index := 0)
	{
		if !(NvStatus := DllCall("nvml\nvmlDeviceGetHandleByIndex_v2", "UInt", Index, "Ptr*", &hDevice := 0, "CDecl"))
		{
			return hDevice
		}

		return this.ErrorString(NvStatus)
	}



	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: DEVICE.GetName
	; //
	; // Retrieves the name of this device.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetName(hDevice)
	{
		deviceName := Buffer(Const.NVML_DEVICE_NAME_V2_BUFFER_SIZE, 0)
		if !(NvStatus := DllCall("nvml\nvmlDeviceGetName", "Ptr", hDevice, "Ptr", deviceName, "UInt", Const.NVML_DEVICE_NAME_V2_BUFFER_SIZE, "CDecl"))
		{
			return StrGet(deviceName, "CP0")
		}

		return this.ErrorString(NvStatus)
	}



	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: DEVICE.GetTemperature
	; //
	; // Retrieves the current temperature readings for the device, in degrees C.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetTemperature(hDevice := 0)
	{
		if !(hDevice)
		{
			hDevice := this.GetHandleByIndex()
		}
		if !(NvStatus := DllCall("nvml\nvmlDeviceGetTemperature", "Ptr", hDevice, "Int", Const.NVML_TEMPERATURE_GPU, "UInt*", &Temp := 0, "CDecl"))
		{
			return Temp
		}

		return this.ErrorString(NvStatus)
	}


	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: DEVICE.GetUtilizationRates
	; //
	; // Retrieves the current utilization rates for the device's major subsystems.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetUtilizationRates(hDevice := 0)
	{
		if !(hDevice)
		{
			hDevice := this.GetHandleByIndex()
		}
		Utilization := Buffer(8, 0)
		if !(NvStatus := DllCall("nvml\nvmlDeviceGetUtilizationRates", "Ptr", hDevice, "Ptr", Utilization, "CDecl"))
		{
			UTIL := Map()
			UTIL["GPU"]    := NumGet(Utilization, 0, "UInt")
			UTIL["MEMORY"] := NumGet(Utilization, 4, "UInt")
			return UTIL
		}

		return this.ErrorString(NvStatus)
	}

}



; ===== NVML SYSTEM FUNCTIONS =================================================================================================================================================

class SYSTEM extends NVML
{

	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: SYSTEM.GetDriverVersion
	; //
	; // Retrieves the version of the system's graphics driver.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetDriverVersion()
	{
		Version := Buffer(Const.NVML_SYSTEM_DRIVER_VERSION_BUFFER_SIZE, 0)
		if !(NvStatus := DllCall("nvml\nvmlSystemGetDriverVersion", "Ptr", Version, "UInt", Const.NVML_SYSTEM_DRIVER_VERSION_BUFFER_SIZE))
		{
			return StrGet(Version, "CP0")
		}

		return this.ErrorString(NvStatus)
	}



	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	; //
	; // FUNCTION NAME: SYSTEM.GetNVMLVersion
	; //
	; // Retrieves the version of the NVML library.
	; //
	; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	static GetNVMLVersion()
	{
		Version := Buffer(Const.NVML_SYSTEM_NVML_VERSION_BUFFER_SIZE, 0)
		if !(NvStatus := DllCall("nvml\nvmlSystemGetNVMLVersion", "Ptr", Version, "UInt", Const.NVML_SYSTEM_NVML_VERSION_BUFFER_SIZE))
		{
			return StrGet(Version, "CP0")
		}

		return this.ErrorString(NvStatus)
	}

}



; ===== NVML CONSTANTS =====================================================================================================================================================

class Const extends NVML
{
	static NVML_DEVICE_NAME_V2_BUFFER_SIZE        := 96
	static NVML_SYSTEM_DRIVER_VERSION_BUFFER_SIZE := 80
	static NVML_SYSTEM_NVML_VERSION_BUFFER_SIZE   := 80
	static NVML_TEMPERATURE_GPU                   := 0
}



; ===========================================================================================================================================================================
