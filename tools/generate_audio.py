"""Original procedural Juwa score and tonal effects; no samples or external melodies.
Requires numpy + ffmpeg. Music events and reverb wrap at the loop boundary.
"""
from pathlib import Path
import numpy as np
import subprocess, wave, json
ROOT = Path(__file__).resolve().parents[1]
SR = 44100
rng = np.random.default_rng(92826)

def write(name, data, music=False):
    folder = ROOT / 'assets/audio' / ('music' if music else 'sfx')
    folder.mkdir(parents=True, exist_ok=True)
    data = np.nan_to_num(data)
    data -= data.mean(axis=0)
    peak = np.max(np.abs(data))
    data *= min(1, .78 / max(peak, .00001))
    wav = folder / (name + '.wav')
    with wave.open(str(wav), 'wb') as f:
        f.setnchannels(2 if data.ndim == 2 else 1); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((np.clip(data, -1, 1) * 32767).astype('<i2').tobytes())
    if music:
        subprocess.run(['ffmpeg','-y','-v','error','-i',str(wav),'-c:a','aac','-b:a','128k',str(folder/(name+'.m4a'))],check=True)
        wav.unlink()

def tone(midi, duration, kind='bell'):
    t = np.arange(int(SR*duration))/SR; f = 440 * 2**((midi-69)/12)
    attack = np.minimum(t/.012, 1)
    if kind == 'pad':
        y = sum(np.sin(2*np.pi*f*k*t + .15*np.sin(2*np.pi*.23*t))/k**2 for k in [1,2,3,4])
        env = np.sin(np.pi*np.minimum(t/duration,1))**1.3
    elif kind == 'bass':
        y = np.sin(2*np.pi*f*t) + .2*np.sin(4*np.pi*f*t)
        env = attack*np.exp(-t*3/max(duration,.1))
    elif kind == 'keys':
        y = np.sin(2*np.pi*f*t + 1.3*np.sin(2*np.pi*f*2*t)*np.exp(-t*5)) + .18*np.sin(2*np.pi*f*3*t)
        env = attack*np.exp(-t*3.4)
    else:
        y = np.sin(2*np.pi*f*t)+.3*np.sin(2*np.pi*f*2.004*t)*np.exp(-t*4)+.1*np.sin(2*np.pi*f*3*t)
        env = attack*np.exp(-t*5)
    env *= np.minimum((duration-t)/.035,1).clip(0,1)
    return y*env

def compose(name, bpm, chords, kind, seed):
    global rng
    rng = np.random.default_rng(seed)
    beat=60/bpm; length=16*4*beat; n=round(length*SR)
    mix=np.zeros((n,2),dtype=np.float64)
    def add(sample, when, gain=.1, pan=0):
        idx=(np.arange(len(sample))+round(when*SR))%n
        np.add.at(mix[:,0],idx,sample*gain*np.sqrt((1-pan)/2))
        np.add.at(mix[:,1],idx,sample*gain*np.sqrt((1+pan)/2))
    for bar in range(16):
        chord=chords[bar%len(chords)]; start=bar*4*beat
        for j,note in enumerate(chord): add(tone(note,beat*4.8,'pad'),start,.035, (j-1.5)*.25)
        for b in range(4):
            add(tone(chord[0]-24 if b%2==0 else chord[2]-24,beat*.8,'bass'),start+b*beat,.13)
            if kind!='gothic' or b%2==0:
                t=np.arange(int(SR*.16))/SR
                kick=np.sin(2*np.pi*(48*t+2.8*(1-np.exp(-t*30))))*np.exp(-t*30)
                add(kick,start+b*beat,.12)
        for sub in range(8):
            t=np.arange(int(SR*.06))/SR; noise=rng.normal(0,1,len(t)); noise=np.diff(noise,prepend=0)
            add(noise*np.exp(-t*90),start+sub*beat/2,.008,-.25 if sub%2 else .25)
            index=[0,2,1,3,2,1,3,2][(sub+bar%2)%8]
            note=chord[index]+(12 if kind in ['water','magic'] else 0)
            add(tone(note,beat*1.4,'bell' if kind in ['water','magic'] else 'keys'),start+sub*beat/2,.04 if kind=='gothic' else .07, np.sin(sub)*.5)
        if kind=='lounge':
            for b in [1,3]:
                for note in chord: add(tone(note,beat,'keys'),start+b*beat+.018,.055)
    # Short stereo delays and diffuse tails wrap rather than cut off at the seam.
    dry=mix.copy()
    for delay,gain in [(beat*.75,.16),(beat*1.5,.09),(.071,.07),(.137,.05)]:
        mix += np.roll(dry,round(delay*SR),axis=0)[:,::-1]*gain
    mix=np.tanh(mix*1.5)*1.3
    write(name,mix,True)
    return round(length,3)

scores=[
 ('lobby',96,[[60,64,67,71],[57,60,64,67],[62,65,69,72],[55,59,62,65]],'lounge'),
 ('fortune',112,[[60,64,67,72],[65,69,72,76],[57,60,64,67],[55,59,62,67]],'keys'),
 ('fish',92,[[62,65,69,72],[58,62,65,69],[65,69,72,76],[60,64,67,74]],'water'),
 ('vampire',78,[[57,60,64,71],[53,57,60,64],[50,53,57,60],[52,56,59,64]],'gothic'),
 ('wheel',108,[[62,66,69,73],[59,62,66,69],[55,59,62,66],[57,61,64,69]],'keys'),
 ('plinko',104,[[60,63,67,70],[56,60,63,67],[58,62,65,68],[55,59,62,65]],'magic')]
manifest={}
for i,(name,bpm,chords,kind) in enumerate(scores):
    manifest[name]={'seconds':compose(name,bpm,chords,kind,100+i),'bpm':bpm}
    print('Composed',name,flush=True)
for name,notes,timing in [('win',[72,76,79,84],.11),('big_win',[60,64,67,72,76,79,84],.1),('drop',[79,72],.045),('peg',[88],.05),('error',[48,45],.12)]:
    y=np.zeros(int(SR*(len(notes)*timing+.8)))
    for i,note in enumerate(notes):
        v=tone(note,.7,'bell' if name!='error' else 'keys')*.18
        j=round(i*timing*SR); y[j:j+len(v)]+=v
    if name in ['peg','drop','error']:
        duration={'peg':.14,'drop':.26,'error':.5}[name]
        y=y[:int(SR*duration)]
        y[-int(SR*.025):]*=np.linspace(1,0,int(SR*.025))
    write(name,y)
# Seamless quiet mechanical reel rotation: periodic motor and evenly spaced teeth.
t=np.arange(SR)/SR
reel=.035*np.sin(2*np.pi*90*t)+.015*np.sin(2*np.pi*180*t)
for k in range(20):
    j=round(k*SR/20); q=np.arange(int(.016*SR))/SR
    v=rng.normal(0,1,len(q))*np.exp(-q*260)*.1
    reel[j:j+len(v)]+=v
# 8x tiled: the iOS player loops by seek-on-end, which gaps; spins never reach the seam.
write('reel_loop',np.tile(reel,8))
(ROOT/'assets/audio/music/manifest.json').write_text(json.dumps(manifest,indent=2))
