# -*-perl-*- for Emacs
#--------------------------------------------------------------------------------
# INTEL CONFIDENTIAL
#
# Copyright (June 2005)2 (May 2008)3 Intel Corporation All Rights Reserved. 
# The source code contained or described herein and all documents related to the
# source code ("Material") are owned by Intel Corporation or its suppliers or
# licensors. Title to the Material remains with Intel Corporation or its
# suppliers and licensors. The Material contains trade secrets and proprietary
# and confidential information of Intel or its suppliers and licensors. The
# Material is protected by worldwide copyright and trade secret laws and treaty
# provisions. No part of the Material may be used, copied, reproduced, modified,
# published, uploaded, posted, transmitted, distributed, or disclosed in any way
# without Intels prior express written permission.
#
# No license under any patent, copyright, trade secret or other intellectual
# property right is granted to or conferred upon you by disclosure or delivery
# of the Materials, either expressly, by implication, inducement, estoppel or
# otherwise. Any license under such intellectual property rights must be express
# and approved by Intel in writing.
#
#--------------------------------------------------------------------------------
{
################################################################################
# Note: All regular expressions must be placed with single quotes '/example/i' 
#  instead of double quotes "/example/i"
################################################################################
# If this variable is set, the config files in the list are first read in the 
#   order listed (so it is possible to overwrite information from an ealier 
#   cfgfile.)  Then the remainder of this file is parsed so that the information
#   contained within this file has the highest precedence.
#
# Note: Only one level of hierarchy can exist (so a file listed here cannot then
#   call an additional base config file.)
#
################################################################################

@BASE_CFG_FILES = (
);

%PATTERNS_DEF = (
    # Each of the defined "modes" are checked inside of postsim.pl.  If no modes
    #   are ever "turned on" the test is automatically a fail.
    Modes => {
        main_mode => {
            Required     => 1,
            StartString  => '/SIM OUTPUT START/',
            EndString    => '/SIM OUTPUT END/', 
            RequiredText => [
                '/UVM Report Summary/',
            ],
            okErrors     => [
                '/UVM_ERROR\s*:\s*0\s*$/',
                '/UVM_FATAL\s*:\s*0\s*$/',
            ],
        },

    },

# List of classified errors to look for.
# The parser searchs for 'All' first. Then tries to classify
# For instance,
# # ** Error: static memory checker error : C17 : - SRAM - ....
# The above error is matches first with the 'All' regular expression.
# Then it matches with the '1 Static_Mem' classification.
# The Number in front of classification is used to order the
# error types, ie, 1 is more serious than 2.
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: These errors are only matched when one of the above "modes" is active,
#  otherwise they are IGNORED!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    Errors => [
        # Error regular expr                          Category    Severity
        [ '/Error/i',                            "ALL",       1        ],
        [ '/Fatal/i',                            "ALL",       1        ],
        [ '/RT Warning:/i',                      "ALL",       1        ],        # RTL assertions
        [ '/Offending/i',                        "ALL",       1        ],        # RTL assertions
        [ '/RASSERT/i',                          "ALL",       1        ],        # PCODE assertions
        # Top level module is blackbox
        [ '/\d+\s*\S+\s*hdl-94\s*Top level design is black-boxed\./', "ALL", 1 ],
        # FPV failures
        [ '/^\[\d*\].*undetermined/',                 "ALL",      2        ],
        [ '/^\[\d*\].*cex/',                          "ALL",      1        ],
        [ '/^\[\d*\].*unreachable/',                  "ALL",      1        ],

    ],

    # Timeout strings which result in a postsim.fail with status of "Timeout"
    TimeoutErrors => [
        '/Simulation TIMEOUT reached/i',
    ],

    # This is a list of errors which are to be considered FATAL errors regardless of
    # whether they show up before or after the "StartOn" or "EndOn" conditions.
    FatalErrors => [
        #'/Fatal/i',
    ],

    # Defines a list of warnings to look for
    Warnings     => [
        '/Low Power Message Summary/',
        '/INFO = \d+, WARNING = \d+, ERROR = \d+, FATAL = \d+/',
    ],

    # Any additional information that is required from the logfile can be entered here:
    #
    # This is what is already extracted:
    #   Test name:
    #   Test type:  (Verilog procedural or Xscale assembly)
    #   Status:
    #   Cause: (for fails only)
    #   Error Count: 
    #   Warning Count:
    #   SIMPLI Error Count:
    #   SIMPLI Check Count:

    ## Default test type is "proc" procedural.  Gets changed to "asm" for assembly if the
    ##  following regular expression matches in the transcript.
    TestType     => {
        Default => {
            regex   => undef,
            keyword => "Proc",
        },
        Assembly => {
            regex   => '/Reading test memory image/',
            keyword => "Asm",
        },
    },

    TestInfo     => [
        # Use this to add to, or overwrite the standards
        # defined in $ACE_HOME/udf/ace_test_info.pp
        ['/Stuck-at fault coverage = (\d+.\d+)%/',            "Stuck-at fault coverage",      '$1'],
        ['/Stuck-at test coverage = (\d+.\d+)%/',             "Stuck-at test coverage",       '$1'],
        ['/Percentage of scannable flops = (\d+.\d+)%/',      "Percentage of scannable flops",'$1'],
        ["/Generating moresimple report from .* to '(.*)'/",  "Moresimple report",            '$1'],
    ],

    # Simple calulations based on contents of the 'TestInfo' array
    Calculations => {
        SimRate => '($TestInfo{Runtime} != 0) ? $TestInfo{Cycles}/$TestInfo{Runtime} : 0',
    },
);
};
