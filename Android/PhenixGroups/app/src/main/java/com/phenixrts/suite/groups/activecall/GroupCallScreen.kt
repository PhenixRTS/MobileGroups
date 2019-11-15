/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.models.RoomModel
import com.phenixrts.suite.groups.phenix.PhenixComponent
import com.phenixrts.suite.groups.phenix.PhenixRoomAdapter
import com.phenixrts.suite.groups.viewmodels.*
import kotlinx.android.synthetic.main.group_call_fragment.*

class GroupCallScreen : Fragment() {

    private val roomViewModel: RoomViewModel by viewModels({ activity!! })
    private val participantsViewModel: ParticipantsViewModel by viewModels({ activity!! })
    private val chatViewModel: ChatViewModel by viewModels({ activity!! })
    private val previewViewModel: PreviewViewModel by viewModels({ activity!! })
    private val callSettings: CallSettingsViewModel by viewModels({ activity!! })

    private val roomModel: RoomModel by lazy { PhenixRoomAdapter(PhenixComponent.roomExpress, callSettings) }


    init {
        retainInstance = true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        roomViewModel.initialize(roomModel)
        participantsViewModel.initialize(roomModel)
        chatViewModel.init(roomModel)
        previewViewModel.initialize(roomModel)

        roomModel.subscribe()
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.group_call_fragment, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        servicePager?.adapter = GroupCallScreenPageAdapter(resources, childFragmentManager)
    }

    override fun onDestroy() {
        roomModel.unsubscribe()
        activity?.viewModelStore?.clear()
        super.onDestroy()
    }
}