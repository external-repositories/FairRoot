/*
 * File:   FairTestDetectorFileSink.tpl
 * Author: winckler, A. Rybalchenko
 *
 * Created on March 11, 2014, 12:12 PM
 */

// Implementation of FairTestDetectorFileSink::Run() with Google Protocol Buffers transport data format

#ifdef PROTOBUF
#include "FairTestDetectorPayload.pb.h"

template<>
void FairTestDetectorFileSink<FairTestDetectorHit, TestDetectorProto::HitPayload>::InitTask()
{
    OnData(fInChannelName, [this](FairMQMessagePtr& msg, int /*index*/) {
        ++fReceivedMsgs;
        fOutput->Delete();

        TestDetectorProto::HitPayload hp;
        hp.ParseFromArray(msg->GetData(), msg->GetSize());

        int numEntries = hp.hit_size();

        for (int i = 0; i < numEntries; ++i) {
            const TestDetectorProto::Hit& hit = hp.hit(i);
            TVector3 pos(hit.posx(), hit.posy(), hit.posz());
            TVector3 dpos(hit.dposx(), hit.dposy(), hit.dposz());
            new ((*fOutput)[i]) FairTestDetectorHit(hit.detid(), hit.mcindex(), pos, dpos);
        }

        if (fOutput->IsEmpty()) {
            LOG(error) << "FairTestDetectorFileSink::Run(): No Output array!";
        }

        FairMQMessagePtr ack(fTransportFactory->CreateMessage());
        fChannels.at(fAckChannelName).at(0).Send(ack);

        fTree.Fill();

        return true;
    });
}

#endif /* PROTOBUF */
