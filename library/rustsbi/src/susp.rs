use sbi_spec::binary::SbiRet;

/// System-Suspend extension.
///
/// The system-suspend extension defines a set of system-level sleep states and a
/// function which allows the supervisor-mode software to request that the system
/// transitions to a sleep state. Sleep states are identified with 32-bit wide
/// identifiers (`sleep_type`). The possible values for the identifiers are shown
/// in the table below:
///
/// | Type                    | Name           | Description
/// |-------------------------|----------------|-------------------------------
/// | 0                       | SUSPEND_TO_RAM | This is a "suspend to RAM" sleep type, similar to ACPI’s S2 or S3. Entry requires all but the calling hart be in the HSM `STOPPED` state and all hart registers and CSRs saved to RAM.
/// | 0x00000001 - 0x7fffffff |                | Reserved for future use
/// | 0x80000000 - 0xffffffff |                | Platform-specific system sleep types
/// | > 0xffffffff            |                | Reserved
///
/// The term "system" refers to the world-view of supervisor software. The
/// underlying SBI implementation may be provided by machine mode firmware or a
/// hypervisor.
///
/// The system suspend extension does not provide any way for supported sleep types
/// to be probed. Platforms are expected to specify their supported system sleep
/// types and per-type wake-up devices in their hardware descriptions. The
/// `SUSPEND_TO_RAM` sleep type is the one exception, and its presence is implied
/// by that of the extension.
pub trait Susp {
    /// Request the SBI implementation to put the system transitions to a sleep state.
    ///
    /// A return from a `system_suspend()` call implies an error and an error code
    /// will be in `sbiret.error`.
    /// A successful suspend and wake up operation results in the
    /// hart, which initiated to suspend, resuming from the `STOPPED` state.
    /// To resume, the hart will jump to supervisor-mode, at the address specified by `resume_addr`,
    /// with the specific register values described in the table below.
    ///
    /// | Register Name                                     | Register Value
    /// | ------------------------------------------------- | ------------------
    /// | satp                                              | 0
    /// | sstatus.SIE                                       | 0
    /// | a0                                                | hartid
    /// | a1                                                | `opaque` parameter
    /// All other registers remain in an undefined state.
    ///
    /// # Parameters
    ///
    /// The `resume_addr` parameter points to a runtime-specified physical address,
    /// where the hart can resume execution in supervisor-mode after a system suspend.
    ///
    /// *NOTE:* A single `usize` parameter is sufficient as `resume_addr`,
    /// because the hart will resume execution in supervisor-mode with the MMU off,
    /// hence `resume_addr` must be less than XLEN bits wide.
    ///
    /// The `opaque` parameter is an XLEN-bit value that will be set in the `a1`
    /// register when the hart resumes execution at `resume_addr` after a
    /// system suspend.
    ///
    /// Besides ensuring all entry criteria for the selected sleep type are met, such
    /// as ensuring other harts are in the `STOPPED` state, the caller must ensure all
    /// power units and domains are in a state compatible with the selected sleep type.
    /// The preparation of the power units, power domains, and wake-up devices used for
    /// resumption from the system sleep state is platform-specific and beyond the
    /// scope of this specification.
    ///
    /// When supervisor software is running inside a virtual machine, the SBI
    /// implementation is provided by a hypervisor.
    /// The system suspend will behave
    /// functionally the same as the native case, but might not result in any physical
    /// power changes.
    ///
    /// # Return value
    ///
    /// The possible return error codes returned in `SbiRet.error` are shown in the table below:
    ///
    /// | Error code                  | Description
    /// | --------------------------- | -------------------
    /// | `SbiRet::success()`         | System has been suspended and resumed successfully.
    /// | `SbiRet::invalid_param()`   | `sleep_type` is reserved or is platform-specific and unimplemented.
    /// | `SbiRet::not_supported()`   | `sleep_type` is not reserved and is implemented, but the platform does not support it due to one or more missing dependencies.
    /// | `SbiRet::invalid_address()` | `resume_addr` is not valid, possibly because it is not a valid physical address, or because executable access is prohibited (e.g. by physical memory protection or H-extension G-stage for supervisor mode).
    /// | `SbiRet::denied()` | The suspend request failed due to unsatisfied entry criteria.
    /// | `SbiRet::failed()` | The suspend request failed for unspecified or unknown other reasons.
    fn system_suspend(&self, sleep_type: u32, resume_addr: usize, opaque: usize) -> SbiRet;
    /// Function internal to macros. Do not use.
    #[doc(hidden)]
    #[inline]
    fn _rustsbi_probe(&self) -> usize {
        sbi_spec::base::UNAVAILABLE_EXTENSION.wrapping_add(1)
    }
}

impl<T: Susp> Susp for &T {
    #[inline]
    fn system_suspend(&self, sleep_type: u32, resume_addr: usize, opaque: usize) -> SbiRet {
        T::system_suspend(self, sleep_type, resume_addr, opaque)
    }
}

impl<T: Susp> Susp for Option<T> {
    #[inline]
    fn system_suspend(&self, sleep_type: u32, resume_addr: usize, opaque: usize) -> SbiRet {
        self.as_ref().map_or(SbiRet::not_supported(), |inner| {
            T::system_suspend(inner, sleep_type, resume_addr, opaque)
        })
    }
    #[inline]
    fn _rustsbi_probe(&self) -> usize {
        match self {
            Some(_) => sbi_spec::base::UNAVAILABLE_EXTENSION.wrapping_add(1),
            None => sbi_spec::base::UNAVAILABLE_EXTENSION,
        }
    }
}
