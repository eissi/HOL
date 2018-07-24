#!/bin/sh

VOLUME=$1
INSTANCE=$2
VOL_TYPE=$3

#echo $VOLUME $INSTANCE

echo [$(date)] Requesting a snapshot!
SNAPID=$(aws ec2 create-snapshot --volume-id $1 --query "SnapshotId" --output text)

echo [$(date)] Waiting for completing the snapshot!
SNAP_RESULT="pending"

while [ "$SNAP_RESULT" != "completed" ]
do
	SNAP_RESULT=$(aws ec2 describe-snapshots --snapshot-ids $SNAPID --query "Snapshots[*].{id:State}" --output text)
	#echo $SNAP_RESULT
	sleep 1
done

echo [$(date)] Finished the snapshot!

AZ=$(aws ec2 describe-instances --instance-ids $2 --query "Reservations[*].Instances[*].Placement.{az:AvailabilityZone}" --output text)
PLATFORM=$(aws ec2 describe-instances --instance-ids $2 --query "Reservations[*].Instances[*].Platform" --output text)

echo [$(date)] Creating a volume from the snapshot, $SNAPID
VOL_ID=$(aws ec2 create-volume --availability-zone $AZ --snapshot-id $SNAPID --volume-type $VOL_TYPE --query "VolumeId" --output text)

VOL_REULST="creating"
while [ "$VOL_REULST" != "available" ]
do
	VOL_REULST=$(aws ec2 describe-volumes --volume-ids $VOL_ID --query "Volumes[*].{st:State}" --output text)
done

echo [$(date)] Finished creating the volume!

if [ "$PLATFORM" == "windows" ]
	then
		STATE=$(aws ec2 attach-volume --volume-id $VOL_ID --instance-id $INSTANCE --device xvdp --query "State" --output text)
	else
		STATE=$(aws ec2 attach-volume --volume-id $VOL_ID --instance-id $INSTANCE --device /dev/sdp --query "State" --output text)
fi

if [ "$STATE" == "attaching" ]
	then
		echo [$(date)] the volume was attaching to the instance, $INSTANCE
	else
		echo [$(date)] FAILED in attaching the volume to the instance, $INSTANCE
		exit 1
fi
