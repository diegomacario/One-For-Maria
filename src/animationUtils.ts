export enum Interpolation {
  Constant,
  Linear,
  Cubic,
}

export class Frame {
  mValue: number;
  mInSlope: number;
  mOutSlope: number;
  mTime: number;

  constructor() {
    this.mValue = 0;
    this.mInSlope = 0;
    this.mOutSlope = 0;
    this.mTime = 0;
  }
}

export class Track {
  mFrames: Frame[];
  mInterpolation: Interpolation;

  constructor() {
    this.mFrames = [];
    this.mInterpolation = Interpolation.Linear;
  }

  getFrame(frameIndex: number): Frame {
    return this.mFrames[frameIndex];
  }

  setFrame(frameIndex: number, frame: Frame): void {
    this.mFrames[frameIndex] = frame;
  }

  getNumberOfFrames(): number {
    return this.mFrames.length;
  }

  setNumberOfFrames(numFrames: number): void {
    while (this.mFrames.length < numFrames) {
      this.mFrames.push(new Frame());
    }
    while (this.mFrames.length > numFrames) {
      this.mFrames.pop();
    }
  }

  getInterpolation(): Interpolation {
    return this.mInterpolation;
  }

  setInterpolation(interpolation: Interpolation): void {
    this.mInterpolation = interpolation;
  }

  getStartTime(): number {
    return this.mFrames[0].mTime;
  }

  getEndTime(): number {
    return this.mFrames[this.mFrames.length - 1].mTime;
  }

  sample(time: number, looping: boolean): number {
    if (this.mInterpolation === Interpolation.Constant) {
      return this.sampleConstant(time, looping);
    } else if (this.mInterpolation === Interpolation.Linear) {
      return this.sampleLinear(time, looping);
    } else {
      return this.sampleCubic(time, looping);
    }
  }

  getIndexOfLastFrameBeforeTime(time: number, looping: boolean): number {
    const numFrames = this.mFrames.length;
    if (numFrames <= 1) {
      return -1;
    }

    let adjustedTime = time;
    if (looping) {
      const startTime = this.mFrames[0].mTime;
      const endTime = this.mFrames[numFrames - 1].mTime;
      const duration = endTime - startTime;

      adjustedTime =
        ((((time - startTime) % duration) + duration) % duration) + startTime;
    } else {
      if (time <= this.mFrames[0].mTime) {
        return 0;
      }

      if (time >= this.mFrames[numFrames - 2].mTime) {
        return numFrames - 2;
      }
    }

    for (let i = numFrames - 1; i >= 0; --i) {
      if (adjustedTime >= this.mFrames[i].mTime) {
        return i;
      }
    }

    return -1;
  }

  adjustTimeToBeWithinTrack(time: number, looping: boolean): number {
    const numFrames = this.mFrames.length;
    if (numFrames <= 1) {
      return 0.0;
    }

    const startTime = this.mFrames[0].mTime;
    const endTime = this.mFrames[numFrames - 1].mTime;
    const duration = endTime - startTime;
    if (duration <= 0.0) {
      return 0.0;
    }

    let adjustedTime = time;
    if (looping) {
      adjustedTime =
        ((((time - startTime) % duration) + duration) % duration) + startTime;
    } else {
      if (time <= this.mFrames[0].mTime) {
        adjustedTime = startTime;
      }

      if (time >= this.mFrames[numFrames - 1].mTime) {
        adjustedTime = endTime;
      }
    }

    return adjustedTime;
  }

  interpolateUsingCubicHermiteSpline(
    t: number,
    p1: number,
    outTangentOfP1: number,
    p2: number,
    inTangentOfP2: number
  ): number {
    const t2 = t * t;
    const t3 = t2 * t;

    const basisFuncOfP1 = 2.0 * t3 - 3.0 * t2 + 1.0;
    const basisFuncOfOutTangentOfP1 = t3 - 2.0 * t2 + t;
    const basisFuncOfP2 = -2.0 * t3 + 3.0 * t2;
    const basisFuncOfInTangentOfP2 = t3 - t2;

    const result =
      p1 * basisFuncOfP1 +
      outTangentOfP1 * basisFuncOfOutTangentOfP1 +
      p2 * basisFuncOfP2 +
      inTangentOfP2 * basisFuncOfInTangentOfP2;

    return result;
  }

  sampleConstant(time: number, looping: boolean): number {
    const frame = this.getIndexOfLastFrameBeforeTime(time, looping);
    if (frame < 0 || frame >= this.mFrames.length) {
      return 0;
    }
    return this.mFrames[frame].mValue;
  }

  sampleLinear(time: number, looping: boolean): number {
    const thisFrame = this.getIndexOfLastFrameBeforeTime(time, looping);
    if (thisFrame < 0 || thisFrame >= this.mFrames.length - 1) {
      return 0;
    }

    const nextFrame = thisFrame + 1;
    const timeBetweenFrames =
      this.mFrames[nextFrame].mTime - this.mFrames[thisFrame].mTime;
    if (timeBetweenFrames <= 0.0) {
      return 0;
    }

    const trackTime = this.adjustTimeToBeWithinTrack(time, looping);
    const t = (trackTime - this.mFrames[thisFrame].mTime) / timeBetweenFrames;

    const start = this.mFrames[thisFrame].mValue;
    const end = this.mFrames[nextFrame].mValue;

    return start + (end - start) * t;
  }

  sampleCubic(time: number, looping: boolean): number {
    const thisFrame = this.getIndexOfLastFrameBeforeTime(time, looping);
    if (thisFrame < 0 || thisFrame >= this.mFrames.length - 1) {
      return 0;
    }

    const nextFrame = thisFrame + 1;
    const timeBetweenFrames =
      this.mFrames[nextFrame].mTime - this.mFrames[thisFrame].mTime;
    if (timeBetweenFrames <= 0.0) {
      return 0;
    }

    const trackTime = this.adjustTimeToBeWithinTrack(time, looping);
    const t = (trackTime - this.mFrames[thisFrame].mTime) / timeBetweenFrames;

    const p1 = this.mFrames[thisFrame].mValue;
    const outTangentOfP1 =
      this.mFrames[thisFrame].mOutSlope * timeBetweenFrames;
    const p2 = this.mFrames[nextFrame].mValue;
    const inTangentOfP2 = this.mFrames[nextFrame].mInSlope * timeBetweenFrames;

    return this.interpolateUsingCubicHermiteSpline(
      t,
      p1,
      outTangentOfP1,
      p2,
      inTangentOfP2
    );
  }
}
